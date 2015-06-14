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
  
  def test_exercise_adj_et_for_pct_cover_when_ref_et_is_0
    50.times do |pct_cover|
      assert_in_delta(0.0, adj_et_pct_cover(0.0,pct_cover),10 ** -8,"Wrong adj et when pct_cover is #{pct_cover}")
    end
    
  end
  
end  
