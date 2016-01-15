require 'test_helper'

class EtCalculatorTest < ActiveSupport::TestCase
  include ETCalculator
  
  def setup
    # data stolen directly from the LAI-vs-DD CSV from which we extracted the polynomial
    # =-0.000003*B133^2 + 0.0073*B133 - 0.6728
    @test_days = [
      [52,-0.301312],
      [104,0.053952],
      [196,0.642752],
      [508,2.261408],
      [1013,3.643593],
      [1504,3.520352],
      [1991,1.969257],
      
    ]
  end
  
  test "fake thermal LAI method gives data we regressed it from" do
    @test_days.each do |test_day_arr|
      assert_in_delta(test_day_arr[1], fake_lai_thermal(test_day_arr[0]), 2 ** -20,"Wrong LAI for #{test_day_arr[0]}")
    end
  end
end
