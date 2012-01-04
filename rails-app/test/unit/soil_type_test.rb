require 'test_helper'

class SoilTypeTest < ActiveSupport::TestCase
  test "default really is sandy loam" do
    assert_equal('Sandy Loam', SoilType.default_soil_type.name)
  end
end
