require 'test_helper'

class WeatherStationsControllerTest < ActionController::TestCase
  setup do
    AuthenticationHelper::USING_OPENID=false if AuthenticationHelper::USING_OPENID
    @weather_station = weather_stations(:one)
  end

end
