require "test/unit"
require "asigbiophys"

# Exercise the ADCalculator module from the asigbiophys gem.
class TestAd < Test::Unit::TestCase
  include ETCalculator
  
  def test_testing_framework_functions
    assert(true)
  end
  
  def test_can_call_a_method_from_ETCalculator
    adj_et_pct_cover(0.2,0.8)
  end
end  
