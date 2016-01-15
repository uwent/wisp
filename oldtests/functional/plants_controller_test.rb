require 'test_helper'

class PlantsControllerTest < ActionController::TestCase
  setup do
    @plant = plants(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:plants)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create plant" do
    assert_difference('Plant.count') do
      post :create, :plant => @plant.attributes
    end

    assert_redirected_to plant_path(assigns(:plant))
  end

  test "should show plant" do
    get :show, :id => @plant.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @plant.to_param
    assert_response :success
  end

  test "should update plant" do
    put :update, :id => @plant.to_param, :plant => @plant.attributes
    assert_redirected_to plant_path(assigns(:plant))
  end

  test "should destroy plant" do
    assert_difference('Plant.count', -1) do
      delete :destroy, :id => @plant.to_param
    end

    assert_redirected_to plants_path
  end
end
