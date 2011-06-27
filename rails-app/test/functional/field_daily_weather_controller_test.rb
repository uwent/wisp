require 'test_helper'

class FieldDailyWeatherControllerTest < ActionController::TestCase
  setup do
    @field_daily_weather = field_daily_weather(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:field_daily_weather)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create field_daily_weather" do
    assert_difference('FieldDailyWeather.count') do
      post :create, :field_daily_weather => @field_daily_weather.attributes
    end

    assert_redirected_to field_daily_weather_path(assigns(:field_daily_weather))
  end

  test "should show field_daily_weather" do
    get :show, :id => @field_daily_weather.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @field_daily_weather.to_param
    assert_response :success
  end

  test "should update field_daily_weather" do
    put :update, :id => @field_daily_weather.to_param, :field_daily_weather => @field_daily_weather.attributes
    assert_redirected_to field_daily_weather_path(assigns(:field_daily_weather))
  end

  test "should destroy field_daily_weather" do
    assert_difference('FieldDailyWeather.count', -1) do
      delete :destroy, :id => @field_daily_weather.to_param
    end

    assert_redirected_to field_daily_weather_index_path
  end
end
