require "test/unit"
require "asigbiophys"

class TestAd < Test::Unit::TestCase
  include ADCalculator
  
  def test_testing_framework_functions
    assert(true)
  end
  
  def test_can_call_a_method_from_ADCalculator
    assert(taw(0.15,0.08,36))
  end
  
end  
