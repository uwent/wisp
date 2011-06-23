require 'test_helper'

class PivotsControllerTest < ActionController::TestCase
  setup do
    @pivot = pivots(:one)
    session[:user_id] = users(:rick)[:id]
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pivots)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pivot" do
    assert_difference('Pivot.count') do
      post :create, :pivot => @pivot.attributes
    end

    assert_redirected_to pivot_path(assigns(:pivot))
  end

  test "should show pivot" do
    get :show, :id => @pivot.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @pivot.to_param
    assert_response :success
  end

  test "should update pivot" do
    put :update, :id => @pivot.to_param, :pivot => @pivot.attributes
    assert_redirected_to pivot_path(assigns(:pivot))
  end

  test "should destroy pivot" do
    assert_difference('Pivot.count', -1) do
      delete :destroy, :id => @pivot.to_param
    end

    assert_redirected_to pivots_path
  end
end
