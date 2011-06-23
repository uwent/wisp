require 'test_helper'

class FarmsControllerTest < ActionController::TestCase
  setup do
    @farm = farms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:farms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create farm" do
    assert_difference('Farm.count') do
      post :create, :farm => @farm.attributes
    end

    assert_redirected_to farm_path(assigns(:farm))
  end

  test "should show farm" do
    get :show, :id => @farm.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @farm.to_param
    assert_response :success
  end

  test "should update farm" do
    put :update, :id => @farm.to_param, :farm => @farm.attributes
    assert_redirected_to farm_path(assigns(:farm))
  end

  test "should destroy farm" do
    assert_difference('Farm.count', -1) do
      delete :destroy, :id => @farm.to_param
    end

    assert_redirected_to farms_path
  end
end
