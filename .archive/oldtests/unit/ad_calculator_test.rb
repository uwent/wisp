require "test_helper"

class AdCalculatorTest < ActiveSupport::TestCase
  include ADCalculator

  test "daily_ad_and_dd with no change" do
    previous_ad = 4.86
    delta_storage = 0.0
    mad_frac = 0.5
    total_available_water = 19.44
    ad, deep_drainage = daily_ad_and_dd(previous_ad, delta_storage, mad_frac, total_available_water)
    assert_in_delta(previous_ad, ad, 2**-20)
    assert_in_delta(0.0, deep_drainage, 2**-20)
  end

  test "ad_max_inches" do
    assert_in_delta(1.8, ad_max_inches(0.5, 3.6), 2**-20)
  end
end
