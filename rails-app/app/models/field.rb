require 'net/http'
require 'uri'

class RingBuffer
  @vals = nil
  attr_accessor :last_nonzero
  
  EPSILON = 0.00000001
  
  def self.big_enough(val)
    val && (0.0 - val).abs > EPSILON
  end
  
  def initialize(size=10)
    @vals = Array.new(size)
    @last = -1
    @n_vals = 0
    @last_nonzero = nil
  end
  
  def add(val)
    return unless val # Ignore nils
    @last = (@last + 1) % @vals.size
    @vals[@last] = val
    @n_vals += 1 if @n_vals < @vals.size
    # record last nonzero value added
    @last_nonzero = val if RingBuffer.big_enough(val)
  end

  def max
    return nil unless @n_vals > 0
    @vals[0..@n_vals-1].max
  end
  
  def mean(ignore_zeros=false)
    return nil unless @n_vals > 0
    if ignore_zeros
      sum,num_nonzero_vals = @vals[0..@n_vals-1].inject([0.0,0]) do |sums, val|
        if RingBuffer.big_enough(val)
          [sums[0] + val,sums[1] + 1]
        else
          sums
        end
      end
      if num_nonzero_vals == 0
        nil
      else
        sum / num_nonzero_vals.to_f
      end
    else
      (@vals[0..@n_vals-1].inject(0.0) { |sum, val| sum + val } || 0.0).to_f / @n_vals.to_f
    end
  end
  
  def dump
    [@last,@n_vals,@vals]
  end
end

class Field < ActiveRecord::Base
  after_create :create_dependent_objects
  before_destroy :mother_may_i  # check with parent if it's OK to go
  
  START_DATE = [4,1]
  END_DATE = [11,30]
  EMERGENCE_DATE = [5,1]
  DEFAULT_FIELD_CAPACITY = 0.31
  DEFAULT_PERM_WILTING_PT = 0.14
  EPSILON = 0.0000001
  
  include ADCalculator
  include ETCalculator
  
  belongs_to :pivot
  belongs_to :soil_type
  has_many :crops, :dependent => :destroy
  has_many :field_daily_weather, :dependent => :destroy, :order => :date # , :autosave => true
  
  before_save :target_ad_pct_or_nil
  after_save :set_fdw_initial_moisture, :do_balances
  
  #
  # ACCESSORS
  #
  
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

  def field_capacity_pct=(val)
    val = val.to_f / 100.0
    write_attribute(:field_capacity, val)
  end
  
  def field_capacity=(val)
    write_attribute(:field_capacity, val.to_f)
  end

  def field_capacity_pct
    field_capacity * 100.0
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

  def perm_wilting_pt=(val)
    write_attribute(:perm_wilting_pt,val.to_f)
  end
  
  def perm_wilting_pt_pct
    perm_wilting_pt * 100.0
  end

  def perm_wilting_pt_pct=(val)
    write_attribute(:perm_wilting_pt,val.to_f / 100.0)
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
      days_since_emergence = date - current_crop.emergence_date
      if et_method.class == LaiEtMethod
        lai = days_since_emergence >= 0 ? lai_corn(days_since_emergence) : 0.0
        pct_cover = nil
      elsif et_method.class == PctCoverEtMethod
        pct_cover = 0.0
        lai = nil
      end
      field_daily_weather << FieldDailyWeather.new(
        :date => date, :ref_et => 0.0, :adj_et => 0.0, :leaf_area_index => lai, :calculated_pct_cover => pct_cover
      )
    end
    set_fdw_initial_moisture
  end
  
  def create_crop
    # puts "create crop"
    crops << Crop.new(:name => "New crop (field ID: #{self[:id]})", :variety => 'A variety', :emergence_date => default_emergence_date,
      :max_root_zone_depth => 36.0, :max_allowable_depletion_frac => 0.5, :initial_soil_moisture => 100*self.field_capacity,
      :dont_update_canopy => true) # TODO: take this back out?
    # puts "crop created"
  end
  
  def default_emergence_date
    season_start,season_end = date_endpoints
    Date.civil(season_start.year,*EMERGENCE_DATE)
  end
  
  # When we're called with default params (e.g. when a Pivot is created, choose the dates for the season)
  def date_endpoints
    year = pivot.cropping_year || Time.now.year
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
    # puts "about to do the calc with crop's initial moisture at #{obs_pct_moisture}"
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
    
    vals = {}
	# To use a test url use "http://agwx.soils.wisc.edu/devel/sun_water/get_grid" Note: et data not automatically updated on devel.
    url = "http://agwx.soils.wisc.edu/uwex_agwx/sun_water/get_grid"
    begin
      uri = URI.parse(url)
	  #logger.info uri
      # Note that we code the nested params with the [] format, since they'll irremediably be
      # formatted to escaped braces if we just use the grid_date => {start_date: } nested hash
      res = response = Net::HTTP.post_form(uri,
        "latitude"=>pivot.latitude, "longitude"=>pivot.longitude, "param"=>"ET",
        "grid_date[start_date]" => start_date, "grid_date[end_date]"=>end_date,
        "format" => "csv")

      vals = {}
      res.body.split("\n").each do |line|
        if line =~ /([\d]{4}-[\d]{2}-[\d]{2}),([\d].[\d]+)$/
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
    (date - fdw_date).to_i
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
  
  def pct_cover_changed_by_date(date)
    pct_cover_changed(field_daily_weather[fdw_index(date)])
  end
  
  def pct_cover_changed(fdw)
    # could re-interpolate everything, but let's just do the ones around the new point
    midpoint_pct_cover = fdw.pct_cover
    fdw_index = field_daily_weather.index {|an_fdw| an_fdw[:date] == fdw[:date]}
    first_fdw_index,last_fdw_index = surrounding(field_daily_weather,fdw_index,:entered_pct_cover)
    if field_daily_weather[first_fdw_index].date < current_crop.emergence_date
      first_fdw_index = field_daily_weather.index { |fdw| fdw.date == current_crop.emergence_date }
    end
    linear_interpolation(field_daily_weather,first_fdw_index,fdw_index,:entered_pct_cover,:calculated_pct_cover)
    if field_daily_weather[last_fdw_index][:entered_pct_cover]
      linear_interpolation(field_daily_weather,fdw_index,last_fdw_index,:entered_pct_cover,:calculated_pct_cover)
    else
      # go one week from last-entered value
      field_daily_weather[fdw_index+1..fdw_index+6].each do |extrapolated_fdw|
        extrapolated_fdw[:calculated_pct_cover] = midpoint_pct_cover
      end
    end
  end
  
  def weather_for(date,end_date=nil)
    if end_date
      field_daily_weather.select { |fdw| fdw.date >= date && fdw.date <= end_date }
    else
      field_daily_weather.select { |fdw| fdw.date == date }
    end
  end
  
  # For a given date range, determine if we have an AD below zero, whether in the range
  # or in the projected data. We assume that the projected data follow the range.
  # Return {self => {date => ad}} or nil if no problems.
  def problem(date=nil,end_date=nil)
    date ||= Date.today
    end_date ||= date + 7
    existing_wx = weather_for(date,end_date)
    projected_ad_data = FieldDailyWeather.projected_ad(existing_wx)
    problem_limit = 0.0
    existing_problems = existing_wx.select do |fdw|
      if fdw && fdw.ad
        fdw.ad < problem_limit
      else
        false
      end
    end
    projected_problem = nil
    projected_ad_data.each_with_index do |prj_ad,ii|
      if prj_ad && prj_ad < problem_limit
        projected_problem = [end_date + ii,prj_ad]
        break
      end
    end
    if existing_problems.size > 0
      {self => [existing_problems.first.date,existing_problems.first.ad]}
    elsif projected_problem
      {self => projected_problem}
    else
      nil
    end
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

  def target_ad_in
    logger.warn "tadi: tadp nil"; return nil unless (tadp = self[:target_ad_pct])
    logger.warn "tadi: cc nil"; return nil unless (cc = current_crop)
    logger.warn "tadi: cmf nil"; return nil unless (crop_mad_frac = cc.max_allowable_depletion_frac)
    logger.warn "tadi: mrzd nil"; return nil unless (mrzd = cc.max_root_zone_depth)
    logger.warn "tadi: fc or pwp nil"; return nil unless (fc = field_capacity) && (pwp = perm_wilting_pt)
    mad_inches = ad_max_inches(crop_mad_frac,taw(fc,pwp,mrzd))
    (tadp / 100.0) * mad_inches
  end
  
  ###### VALIDATORS & LIFECYCLE #########
  def target_ad_pct_or_nil
    if self[:target_ad_pct] != nil
      begin
        self[:target_ad_pct] = self[:target_ad_pct].to_f
        self[:target_ad_pct] = nil if (self[:target_ad_pct] < 1.0) || (self[:target_ad_pct] > 100.0)
        logger.info "field validation: target_ad_pct #{self[:target_ad_pct]}"
      rescue Exception => e
        logger.error "Tried to set field target_ad_pct to #{self[:target_ad_pct]}"
        self[:target_ad_pct] = nil
      end
    end
  end
  
  def set_fdw_initial_moisture
    fc = self[:field_capacity] || field_capacity
    first_fdw = field_daily_weather[0]
    unless (first_fdw && fc)
      logger.warn "set_fdw_initial_moisture called but fc or first fdw was missing"
      return
    end
    first_fdw.calculated_pct_moisture = 100*fc
    pwp = self[:perm_wilting_pt] || perm_wilting_pt
    unless pwp
      logger.warn "set_fdw_initial_moisture: pwp for field was nil, using default soil type"
      pwp = SoilType.initial_types.select { |st| st[:name] == SoilType.DEFAULT_SOIL_TYPE_NAME }.first[:perm_wilting_pt]
    end
    first_fdw.set_ad_from_calculated_moisture(fc,pwp,current_crop.max_root_zone_depth)
    first_fdw.save!
    # puts "set_fdw_initial: set the AD for the first FDW, it's now:"
    # puts first_fdw.inspect
    # do_balances(first_fdw.date + 1)
  end

  def max_adj_et_in_past_week(fdw_index)
    max_index = fdw_index
    max_index = field_daily_weather.size -1 if max_index >= field_daily_weather.size
    fdw_index -= 6
    fdw_index = 0 if fdw_index < 0
    field_daily_weather[fdw_index,max_index].inject(0.0) { |max, fdw| [max,fdw.adj_et].max }
  end
  
  def do_balances(date=nil)
    # puts "do_balances called with date #{date}"
    day = date ? fdw_index(date) : 0
    return unless field_daily_weather && field_daily_weather[0]
    # Get yesterday's index to initialize prev_ad, but don't go below 0!
    prev_ad = field_daily_weather[[0,day - 1].max].ad
    # puts "do_balances going from #{day} onward (date was #{date}), prev_ad #{prev_ad} and starting FDW is"
    # puts field_daily_weather[day].inspect
    # Track previous adjusted ADs as we go, and use the max value from the past week to replace if necessary
    rb = RingBuffer.new(7)
    field_daily_weather[day..-1].each do |fdw|
      # Remember the max adjusted ET within the last week. If there wasn't a nonzero one, use the last available one.
      last_adj_et = rb.max || rb.last_nonzero
      fdw.old_update_balances(prev_ad,last_adj_et)
      prev_ad = fdw.ad
      rb.add(fdw.adj_et) # Add this one's adj_et value to the running list
      fdw.save!
    end
  end
  
  def act # placeholder for dummy JSON info, to be replaced by "action" button in grid
    ""
  end
  
end
