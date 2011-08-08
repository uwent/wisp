require "ad_calculator"
require "et_calculator"

class Field < ActiveRecord::Base
  after_create :create_dependent_objects
  
  START_DATE = [5,1]
  END_DATE = [9,30]
  
  include ADCalculator
  include ETCalculator
  
  belongs_to :pivot
  has_many :crops, :dependent => :destroy
  has_many :field_daily_weather, :autosave => true, :dependent => :destroy
  
  def et_method
    return nil unless pivot && pivot.farm
    pivot.farm.et_method
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

  def create_dependent_objects
    create_field_daily_weather
    create_crop
    save!
  end
  
  def create_field_daily_weather
    # puts "create_fdw"
    start_date,end_date = date_endpoints
    (start_date..end_date).each {|date| field_daily_weather << FieldDailyWeather.new(:date => date)}
  end
  
  def create_crop
    # puts "create crop"
    crops << Crop.new(:name => "New crop (field: #{name})", :variety => 'A variety', :emergence_date => Date.today,
      :max_root_zone_depth => 36.0, :max_allowable_depletion_frac => 0.5, :initial_soil_moisture => self[:field_capacity])
  end
  
  def date_endpoints
    year ||= Time.now.year
    # puts "date_endpoints: #{year} / #{START_DATE[0]} / #{START_DATE[1]}"
    ep1 = Date.civil(year,*START_DATE)
    ep2 = Date.civil(year,*END_DATE)
    [ep1,ep2]
  end
  
  def initial_ad
    unless (current_crop && current_crop.max_root_zone_depth && field_capacity && perm_wilting_pt &&
      current_crop.max_allowable_depletion_frac && current_crop.initial_soil_moisture)
      return -999.0
    end
    mrzd = current_crop.max_root_zone_depth

    taw = calc_taw(field_capacity, perm_wilting_pt, mrzd)
    mad_frac = current_crop.max_allowable_depletion_frac
    
    pct_mad_min = calc_pct_moisture_at_ad_min(field_capacity, calc_ad_max_inches(mad_frac,taw), mrzd)
    
    obs_pct_moisture = current_crop.initial_soil_moisture
    calc_daily_ad_from_moisture(mad_frac,taw,mrzd,pct_mad_min,obs_pct_moisture)
    
  end
  
  def update_canopy(emergence_date)
    if et_method.class == LaiEtMethod
      days_since_emergence = 0
      field_daily_weather.each do |fdw|
        next unless fdw.date >= emergence_date
        fdw.leaf_area_index = calc_lai_corn(days_since_emergence)
        fdw.save!
        days_since_emergence += 1
      end
      save!
    elsif et_method.class == PctCoverEtMethod
      # do the percent cover stuff here
    end
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
end
