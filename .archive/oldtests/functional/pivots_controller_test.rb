require "test_helper"

class PivotsControllerTest < ActionController::TestCase
  setup do
    @pivot = pivots(:one)
    session[:user_id] = users(:rick)[:id]
  end
end
