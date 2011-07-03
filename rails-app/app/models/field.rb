require "ad_calculator"
require "et_calculator"

class Field < ActiveRecord::Base
  after_create :create_field_daily_weather
  
  START_DATE = '03-01'
  END_DATE = '10-31'
  
  include ADCalculator
  include ETCalculator
  
  belongs_to :pivot
  has_many :crops
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
    (crops.sort { |a, b| b.emergence_date <=> a.emergence_date }).first
  end
  
  def year
    return nil unless pivot && pivot.farm
    pivot.farm.year
  end
  
  def create_field_daily_weather
    start_date,end_date = date_endpoints
    (start_date..end_date).each {|date| field_daily_weather << FieldDailyWeather.new(:date => date)}
    save!
  end
  
  def date_endpoints
    [(DateTime.parse year.to_s + '-' + START_DATE),(DateTime.parse year.to_s + '-' + END_DATE)]
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
    fdw_date = DateTime.parse(field_daily_weather.first.date.to_s)
    date - fdw_date
  end
  
  # hook method for FDW objects to alert us of their (newly changed?) AD
  def update_fdw(field_daily_wx)
    day = fdw_index(field_daily_wx.date)
    puts "updating field daily wx for day #{day}"
    unless day == nil || day == 0 # don't bother trying to get the AD balance from a day that doesn't exist
      field_daily_wx.update_balances(field_daily_weather[day-1])
    end
  end
end
