require "test_helper"

# Turn off OpenID auth for functional tests
module AuthenticationHelper
  USING_OPENID = false
end

class CropsControllerTest < ActionController::TestCase
  setup do
    @crop = crops(:one)
    session[:user_id] = users(:rick)
  end
end
