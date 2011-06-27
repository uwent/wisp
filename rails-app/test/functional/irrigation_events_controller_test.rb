require 'test_helper'

class IrrigationEventsControllerTest < ActionController::TestCase
  setup do
    @irrigation_event = irrigation_events(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:irrigation_events)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create irrigation_event" do
    assert_difference('IrrigationEvent.count') do
      post :create, :irrigation_event => @irrigation_event.attributes
    end

    assert_redirected_to irrigation_event_path(assigns(:irrigation_event))
  end

  test "should show irrigation_event" do
    get :show, :id => @irrigation_event.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @irrigation_event.to_param
    assert_response :success
  end

  test "should update irrigation_event" do
    put :update, :id => @irrigation_event.to_param, :irrigation_event => @irrigation_event.attributes
    assert_redirected_to irrigation_event_path(assigns(:irrigation_event))
  end

  test "should destroy irrigation_event" do
    assert_difference('IrrigationEvent.count', -1) do
      delete :destroy, :id => @irrigation_event.to_param
    end

    assert_redirected_to irrigation_events_path
  end
end
