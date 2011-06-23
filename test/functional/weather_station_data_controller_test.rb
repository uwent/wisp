require 'test_helper'

class WeatherStationDataControllerTest < ActionController::TestCase
  setup do
    @weather_station_data = weather_station_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:weather_station_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create weather_station_data" do
    assert_difference('WeatherStationData.count') do
      post :create, :weather_station_data => @weather_station_data.attributes
    end

    assert_redirected_to weather_station_data_path(assigns(:weather_station_data))
  end

  test "should show weather_station_data" do
    get :show, :id => @weather_station_data.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @weather_station_data.to_param
    assert_response :success
  end

  test "should update weather_station_data" do
    put :update, :id => @weather_station_data.to_param, :weather_station_data => @weather_station_data.attributes
    assert_redirected_to weather_station_data_path(assigns(:weather_station_data))
  end

  test "should destroy weather_station_data" do
    assert_difference('WeatherStationData.count', -1) do
      delete :destroy, :id => @weather_station_data.to_param
    end

    assert_redirected_to weather_station_data_path
  end
end
