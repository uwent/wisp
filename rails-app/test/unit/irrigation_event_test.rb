require 'test_helper'

class IrrigationEventTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "field_daily_weather for" do
    weather = irrigation_events(:one).fdw_for
    assert(weather)
    assert(weather.size > 0)
    puts weather.inspect
  end
end
