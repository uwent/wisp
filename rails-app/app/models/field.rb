require "ad_calculator"
require "et_calculator"
require 'net/http'
require 'uri'

class Field < ActiveRecord::Base
  after_create :create_dependent_objects
  before_destroy :mother_may_i  # check with parent if it's OK to go
  
  START_DATE = [5,1]
  END_DATE = [9,30]
  DEFAULT_FIELD_CAPACITY = 0.31
  DEFAULT_PERM_WILTING_PT = 0.14
  EPSILON = 0.0000001
  
  include ADCalculator
  include ETCalculator
  
  belongs_to :pivot
  belongs_to :soil_type
  has_many :crops, :dependent => :destroy
  has_many :field_daily_weather, :autosave => true, :dependent => :destroy
  
  def et_method
    raise "Error: Field with no parent pivot" unless pivot
    raise "Error: Field with no parent farm" unless pivot.farm
    if pivot.farm.et_method
      return pivot.farm.et_method
    else
      # apparently during object construction the ID can be set, but the association isn't real
      raise "Farm has no ET method set: #{pivot.farm.inspect}" unless pivot.farm[:et_method_id]
      EtMethod.find(pivot.farm[:et_method_id])
    end
  end
  
  #FIXME: this is just a placeholder hack for now, returning the one w/the
  # latest emergence date
  
  # pseduocode for the "real" algorithm
  # given a date:
  # look for the latest crop in the current year whose emergence date is past
  def current_crop
    sorted = crops.sort do |a, b|
      b.emergence_date <=> a.emergence_date
    end
    sorted.first
  end
  
  def year
    return Time.now.year unless pivot && pivot.farm
    pivot.farm.year
  end
  
  def field_capacity
    if (val = read_attribute(:field_capacity)) && val != 0.0
      val
    elsif soil_type
      soil_type.field_capacity
    else
      DEFAULT_FIELD_CAPACITY
    end
  end
  
  def perm_wilting_pt
    if (val = read_attribute(:perm_wilting_pt)) && val != 0.0
      val
    elsif soil_type
      soil_type.perm_wilting_pt
    else
      DEFAULT_PERM_WILTING_PT
    end
  end
      

  def create_dependent_objects
    # puts "CDO...#{self.inspect}, fdw #{field_daily_weather.size} records" if et_method.class == PctCoverEtMethod
    create_crop
    # puts "...crops are #{crops.inspect}" if et_method.class == PctCoverEtMethod
    create_field_daily_weather
    # puts "...fdw now #{field_daily_weather.size} records" if et_method.class == PctCoverEtMethod
    crops.each { |crop| crop.dont_update_canopy = false }
    save!
  end
  
  def create_field_daily_weather
    start_date,end_date = date_endpoints
    # puts "create_fdw for #{start_date}, #{end_date}"
    pct_cover = nil
    lai = nil
    (start_date..end_date).each do |date|
      # Could use update_canopy for this, but why go 'round twice? Still, there's a smell.
      days_since_emergence = date - crops.first.emergence_date
      if et_method.class == LaiEtMethod
        lai = days_since_emergence >= 0 ? lai_corn(days_since_emergence) : 0.0
        pct_cover = nil
      elsif et_method.class == PctCoverEtMethod
        pct_cover = 0.0 # Should this be pre-calculated somehow?
        lai = nil
      end
      field_daily_weather << FieldDailyWeather.new(
        :date => date, :ref_et => 0.0, :adj_et => 0.0, :leaf_area_index => lai, :calculated_pct_cover => pct_cover
      )
    end
    # Shouldn't initial soil moisture go in here?
    field_daily_weather[0].calculated_pct_moisture = 100*self.field_capacity
  end
  
  def create_crop
    # puts "create crop"
    crops << Crop.new(:name => "New crop (field: #{name})", :variety => 'A variety', :emergence_date => date_endpoints.first,
      :max_root_zone_depth => 36.0, :max_allowable_depletion_frac => 0.5, :initial_soil_moisture => 100*self.field_capacity,
      :dont_update_canopy => true) # TODO: take this back out?
    # puts "crop created"
  end
  
  def date_endpoints
    year = Time.now.year
    # puts "date_endpoints: #{year} / #{START_DATE[0]} / #{START_DATE[1]}"
    ep1 = Date.civil(year,*START_DATE)
    ep2 = Date.civil(year,*END_DATE)
    [ep1,ep2]
  end
  
  def initial_ad
    # puts "field#initial_ad called"
    unless (current_crop && current_crop.max_root_zone_depth && field_capacity && perm_wilting_pt &&
      current_crop.max_allowable_depletion_frac && current_crop.initial_soil_moisture)
      return -999.0
    end
    mrzd = current_crop.max_root_zone_depth
    taw = taw(field_capacity, perm_wilting_pt, mrzd)
    mad_frac = current_crop.max_allowable_depletion_frac
  # puts "Field#taw returns #{taw}; max allowable depletion frac is #{mad_frac}"
    
    pct_mad_min = pct_moisture_at_ad_min(field_capacity, ad_max_inches(mad_frac,taw), mrzd)
    
    obs_pct_moisture = current_crop.initial_soil_moisture
    # puts "about to do the calc"
    daily_ad_from_moisture(mad_frac,taw,mrzd,pct_mad_min,obs_pct_moisture)
    
  end
  
  def update_canopy(emergence_date)
    if et_method.class == LaiEtMethod
      # FIXME: Would probably speed up creating new fields and crops A LOT if we did defer_balances here!
      days_since_emergence = 0
      field_daily_weather.each do |fdw|
        next unless fdw.date >= emergence_date
        fdw.leaf_area_index = lai_corn(days_since_emergence)
        fdw.save!
        days_since_emergence += 1
      end
      save!
    elsif et_method.class == PctCoverEtMethod
      # There is no automatic canopy calculation for % cover, at least not now. So just set everything that's nil to 0.0.
      FieldDailyWeather.defer_balances
      field_daily_weather.each do |fdw|
        unless fdw.pct_cover # don't bother if already set; checks both calculated and entered
          fdw.calculated_pct_cover = 0.0
          fdw.save!
        end
      end
      FieldDailyWeather.undefer_balances
      # Now that we've gone through and saved everything, we can trigger once through for AD balances
      field_daily_weather.first.save!
    else
      raise "Unknown ET Method for this field: #{et_method.inspect}"
    end
  end

  def get_et
    unless pivot.latitude && pivot.longitude
      logger.info "get_et: no lat/long for pivot"
    end
    logger.info "Starting get_et"
    start_date = field_daily_weather[0].date.to_s
    end_date = field_daily_weather[-1].date.to_s
    
    # http://www.soils.wisc.edu/asig/rails/wimnext-rails/choose_date?controller=et&action=get_et_series&latitude=48.0&longitude=90.8
    vals = {}
    begin
      url = URI.parse("http://www.soils.wisc.edu")
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.get("/asig/rails/wimnext-rails/et/get_et_series?" + 
          "start_date=#{start_date}&end_date=#{end_date}&latitude=#{pivot.latitude}&longitude=#{pivot.longitude}"
        )
      }
      vals = {}
      res.body.split("\n").each do |line|
        if line =~ /([\d]{4}-[\d]{2}-[\d]{2}),([\d].[\d]+)[^\d]/
          vals[$1] = $2.to_f
        end
      end
    rescue Exception => e
      logger.info "Could not get ETs from the net; connected? (#{e.to_s})"
    end
    field_daily_weather.each do |fdw|
      if fdw.ref_et == nil || fdw.ref_et == 0.0
        if vals[fdw.date.to_s]
          fdw.ref_et = vals[fdw.date.to_s]
          fdw.save!
        end
      end
    end
    logger.info "done with get_et"
  end
  
  def fdw_index(date)
    # why the *^$@ can't I just subtract the database field instead of this rigamarole?
    return nil unless field_daily_weather.first
    fdw_date = Date.parse(field_daily_weather.first.date.to_s)
    date - fdw_date
  end
  
  # hook method for FDW objects to alert us of their (newly changed?) AD
  def update_fdw(field_daily_wx)
    # puts "field#update_fdw: wx calling us has #{field_daily_wx.field.inspect}"
    # day = fdw_index(field_daily_wx.date)
    # unless day
    #   puts "Could not calculate the index for the field_daily_wx"
    #   return
    # end
    # puts "updating field daily wx for day #{day}"
    # field_daily_wx.update_balances(day == 0 ? nil : field_daily_weather[day-1])
  end
  
  # return the Max AD (in inches)
  def ad_max
    taw = taw(field_capacity, perm_wilting_pt, current_crop.max_root_zone_depth)
    mad_frac = current_crop.max_allowable_depletion_frac
    ad_max_inches(mad_frac,taw)
  end
  
  def pct_cover_changed(fdw)
    # could re-interpolate everything, but let's just do the ones around the new point
    midpoint_pct_cover = fdw.pct_cover
    fdw_index = field_daily_weather.index {|an_fdw| an_fdw[:date] == fdw[:date]}
    first_fdw,last_fdw = surrounding(field_daily_weather,fdw_index,:entered_pct_cover)
    # puts "fdw_index: #{fdw_index} first_fdw: #{first_fdw} last_fdw: #{last_fdw} midpoint: #{midpoint_pct_cover}fdw: #{fdw.date}, #{fdw.calculated_pct_cover}, #{fdw.entered_pct_cover}, #{fdw.pct_cover}"
    FieldDailyWeather.defer_balances
    linear_interpolation(field_daily_weather,first_fdw,fdw_index,:entered_pct_cover,:calculated_pct_cover)
    if field_daily_weather[last_fdw][:entered_pct_cover]
      linear_interpolation(field_daily_weather,fdw_index,last_fdw,:entered_pct_cover,:calculated_pct_cover)
    else
      # go one week from last-entered value
      field_daily_weather[fdw_index+1..fdw_index+6].each do |extrapolated_fdw|
        extrapolated_fdw[:calculated_pct_cover] = midpoint_pct_cover
        extrapolated_fdw.save!
      end
    end
    FieldDailyWeather.undefer_balances
    # NOW trigger the whole mess!
    # field_daily_weather[first_fdw].save!
  end
  
  def weather_for(date)
    field_daily_weather.select { |fdw| fdw.date == date }
  end
  
  def problem
  end
  
  def mother_may_i
    pivot.may_destroy(self)
  end

  def within_epsilon(val,other_val)
    (val - other_val).abs < EPSILON
  end
  
  # If the incoming attributes have an entry for attrib symbol, and it's the same value (within EPSILON)
  # as the default value for our soil, delete the entry from the attributes.
  def remove_incoming_if_default(my_soil,incoming_attribs,attrib_symbol)
    if incoming_attribs[attrib_symbol] && within_epsilon(incoming_attribs[attrib_symbol].to_f,my_soil[attrib_symbol])
      incoming_attribs.delete(attrib_symbol)
    end
    incoming_attribs
  end                                                                                                      
  
  def groom_for_defaults(incoming_attribs)
    my_soil = soil_type
    if incoming_attribs[:soil_type_id].to_i == soil_type_id
      # why set it if it hasn't changed? Just biff it
      incoming_attribs.delete(:soil_type_id)
    else
      # If the user has changed the soil type, they're overwriting any explicit values they'd previously entered,
      # whether implicitly via the soil type defaults, or explicity via newly-entered values.
      # Note that we could also probably do with with soil_type_id=(), but this is already here.
      self[:field_capacity] = nil
      self[:perm_wilting_pt] = nil
      # Get rid of FC and PWP if they correspond to the old soil's default values.
      # The two remove_incoming lines that get called after this will get rid of ones == to NEW default values.
      remove_incoming_if_default(my_soil,incoming_attribs,:field_capacity)
      remove_incoming_if_default(my_soil,incoming_attribs,:perm_wilting_pt)
      my_soil = SoilType.find(incoming_attribs[:soil_type_id].to_i)
    end
    remove_incoming_if_default(my_soil,incoming_attribs,:field_capacity)
    remove_incoming_if_default(my_soil,incoming_attribs,:perm_wilting_pt)
  end
end
