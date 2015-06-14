require 'test_helper'

class OmniauthCallbacksControllerTest < ActionController::TestCase
  test "should get google_oauth2" do
    get :google_oauth2
    assert_response :success
  end

end
