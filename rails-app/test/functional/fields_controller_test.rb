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
    name = 'should create field test'
    piv_id = pivots(:pivot_pct_2012)[:id]
    assert_difference('Field.count') do
      post :post_data, pivot_id: piv_id, parent_id: piv_id, oper: 'add', id: '_empty', name: name
    end
    fld = Field.find_by_name name
    assert(fld)
    emd = fld.current_crop.emergence_date
    assert(fdw = fld.field_daily_weather.select { |f| f.date == emd }.first)
    assert(before_emergence_fdw = fld.field_daily_weather.select { |f| f.date == emd - 1 }.first)
    assert(after_emergence_fdw = fld.field_daily_weather.select { |f| f.date == emd + 1 }.first)
    assert_nil(before_emergence_fdw.deep_drainage)
    assert_nil(fdw.deep_drainage)
    assert_nil(after_emergence_fdw.deep_drainage)
    fdw.ref_et = 0.2
    fdw.entered_pct_cover = 100
    fdw.save!
    assert_equal(0.0, fdw.deep_drainage)
    assert_nil(before_emergence_fdw.deep_drainage)
    assert_nil(after_emergence_fdw.deep_drainage)
    after_emergence_fdw.ref_et = 0.2
    after_emergence_fdw.save!
    assert_equal(0.0, after_emergence_fdw.deep_drainage)
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
