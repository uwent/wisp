require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  test "should get new" do
    get :new
    assert_response :unauthorized
  end
end
