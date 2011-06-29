require "ad_calculator"

class Field < ActiveRecord::Base
  include ADCalculator
  
  belongs_to :pivot
  has_many :crops
  has_many :field_daily_weather
  
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
end
