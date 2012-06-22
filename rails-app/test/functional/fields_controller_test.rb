require 'test_helper'

class FieldsControllerTest < ActionController::TestCase
  setup do
    @field = fields(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create field" do
    assert_difference('Field.count') do
      post :create, :field => @field.attributes
    end

    assert_redirected_to field_path(assigns(:field))
  end

  test "should show field" do
    get :show, :id => @field.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @field.to_param
    assert_response :success
  end

  test "should update field" do
    put :update, :id => @field.to_param, :field => @field.attributes
    assert_redirected_to field_path(assigns(:field))
  end

  test "should destroy field" do
    assert_difference('Field.count', -1) do
      delete :destroy, :id => @field.to_param
    end

    assert_redirected_to fields_path
  end
  
  test "get appropriate JSON when creating" do
    post :post_data, :oper => 'add', :parent_id => Pivot.first[:id], :pivot_id => Pivot.first[:id]
    assert_response :success
    puts(response.body)
    assert(json = JSON.parse(response.body))
    assert_equal("New field (pivot 1)", json['name'])
  end
  
  # let's just test this here, it's the first controller to use it
  test "jsonify works" do
    assert_equal({"expected_str" => "this", "expected_int" => "2"}, FieldsController.jsonify({:expected_str => 'this', :expected_int => 2}))
  end
end
