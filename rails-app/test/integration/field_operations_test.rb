require 'test_helper'

class ModelControllerTest < ActionController::IntegrationTest
    name = 'createAFieldTest'
    
  test "create a field should set moisture" do
    default_field = fields(:default)
    # puts 'about to post'; $stdout.flush
    post 'fields/post_data', :oper => :add, :pivot_id => default_field.pivot_id, :name => name
    # puts 'posted'; $stdout.flush
    field = Field.find_by_name(name)
    assert_equal(100*field.field_capacity, field.field_daily_weather[0].calculated_pct_moisture,field.inspect+"\n"+field.field_daily_weather[0].inspect)
  end
  
  test "update a field should update pct moisture" do
    default_field = fields(:default)
    # puts 'about to post (add)'; $stdout.flush
    post 'fields/post_data', :oper => :add, :pivot_id => default_field.pivot_id, :name => name
    # puts 'posted'; $stdout.flush
    field = Field.find_by_name(name)
    id = field[:id]
    assert_equal(100*field.field_capacity, field.field_daily_weather[0].calculated_pct_moisture,field.inspect+"\n"+field.field_daily_weather[0].inspect)
    # "pivot_id"=>"2", "oper"=>"edit", "id"=>"2", "authenticity_token"=>"7ooWDab4gnCDubHBTKWkkwELi6bzOztblOUpVaEO2+M=", "parent_id"=>"2"
    # puts 'about to post (edit)'; $stdout.flush
    post 'fields/post_data',
      # Moss
      :oper => :edit, :id => id,  :pivot_id => default_field.pivot_id, :parent_id => default_field.pivot_id, :soil_type_id => field.soil_type_id,
      # What we're actually testing
      :field_capacity_pct => 35.0
      # puts 'posted'; $stdout.flush
    field = Field.find(id)
    assert_equal(35.0, field.field_daily_weather[0].calculated_pct_moisture,field.inspect+"\n"+field.field_daily_weather[0].inspect)
  end
end

