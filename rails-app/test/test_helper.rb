ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  
  def wx_for(things,date)
    things.select { |thing| thing.date.to_s == date }.first
  end

  
  def emergence_index(field)
    field.field_daily_weather.index {|fdw| fdw.date == field.current_crop.emergence_date}
  end
  
end
