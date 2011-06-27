require 'test_helper'

class ThermalModelsControllerTest < ActionController::TestCase
  
  test "wiDDs redirect" do
    get "wiDDs"
    assert_response :redirect
    assert_redirected_to "http://www.soils.wisc.edu/~asig/wiDDs.html"
  end
  
  test "wiDDs_csv" do
    get "wiDDs_csv"
    assert_response :success
  end
  
end
