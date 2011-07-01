require "ad_calculator"

class Field < ActiveRecord::Base
  after_create :create_field_daily_weather
  
  START_DATE = '03-01'
  END_DATE = '10-31'
  
  include ADCalculator
  
  belongs_to :pivot
  has_many :crops
  has_many :field_daily_weather, :dependent => :destroy
  
  def et_method
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
end
