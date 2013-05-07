require 'test_helper'

class PivotTest < ActiveSupport::TestCase
  BASE_YEAR = 2010
  test "clone_for works" do
    pivot = Pivot.first
    assert_nothing_raised(NoMethodError) { newpiv = pivot.clone_for(2200) }
  end
  
  test "clone_for returns a Pivot" do
    pivot = Pivot.first
    assert_equal(Pivot, pivot.clone_for(2020).class)
  end
  
  test "clone_for returns a Pivot with the same attributes" do
    pivot = Pivot.create(name: 'pivot', latitude: 44.5, longitude: -89.2, farm_id: Farm.first[:id], cropping_year: BASE_YEAR)
    piv_attribs = pivot.attributes
    new_pivot = pivot.clone_for(2020)
    new_pivot.attributes.each do |key,val|
      next if key == :id || key == 'id'
      if key == :cropping_year || key == 'cropping_year'
        assert_equal(2020, val.to_i)
      else
        assert_equal(piv_attribs[key], val,"Wrong value for #{key}")
      end
    end
  end
  
  test "clone_for returns a Pivot with the same number of fields" do
    pivot = Pivot.create(name: 'pivot', latitude: 44.5, longitude: -89.2, farm_id: Farm.first[:id], cropping_year: BASE_YEAR)
    5.times { |n| Field.create(field_capacity: 0.2, pivot_id: pivot[:id]) }
    new_pivot = pivot.clone_for(2020)
    assert_equal(pivot.fields.size, new_pivot.fields.size)
  end
  
  test "clone_for returns a Pivot whose fields have the same attributes" do
    pivot = Pivot.create(name: 'pivot', latitude: 44.5, longitude: -89.2, farm_id: Farm.first[:id], cropping_year: BASE_YEAR)
    5.times { |n| Field.create(field_capacity: 0.2, pivot_id: pivot[:id], perm_wilting_pt: 0.05, name: n.to_s) }
    new_pivot = pivot.clone_for(2020)
    5.times do |n|
      new_pivot.fields[n].attributes.each do |key,val|
        unless key == :id || key == 'id' || key == :pivot_id || key == 'pivot_id'
          assert_equal(pivot.fields[n][key], val,"Wrong val for #{key}")
        end
      end
    end
  end
end
