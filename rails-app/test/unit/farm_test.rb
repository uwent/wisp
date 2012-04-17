require 'test_helper'

class FarmTest < ActiveSupport::TestCase
  def setup
    @ricks_group = groups(:ricks)
    @ricks_farms = @ricks_group.farms
  end
  
  test "farms are in correct groups" do
    assert(@ricks_group)
    num_ricks_farms = @ricks_farms.size
    assert(num_ricks_farms > 0, "Rick's group should have some farms")
    num_farms = Farm.count
    assert(num_farms > num_ricks_farms, "Should be farms outside rick's group")
  end
  
  test "my_farms selects only correct farms" do
    my_farms = Farm.my_farms(@ricks_group[:id])
    assert(my_farms, "my_farms should return something")
    assert_equal(@ricks_farms, my_farms,"my_farms should return the same farms as ricks_group")
  end
  
  def needle_hierarchy(name="A farm")
    group_id = Group.first[:id]
    farm = Farm.new(:name => name, :et_method_id => 1, :year => 2012, :group_id => group_id)
    farm.save!
    farm
  end
  
  test "can create the one-element-per-level hierarchy" do
    assert(farm = needle_hierarchy,"what, I can't create a farm?")
    assert_equal(Farm, farm.class,"It should have been a Farm")
    assert_equal(1, farm.pivots.size, "Farms come with pivots by default, don't they?")
    assert_equal(1, farm.pivots.first.fields.size,"and pivots make a field, too")
  end
  
  test "can't destroy the only field" do
    farm = needle_hierarchy
    fields = farm.pivots.first.fields
    result = fields.first.destroy
    fields.reload
    assert_equal(1, fields.size,"Should have been unable to destroy it") 
  end
  
  test "can destroy if more than one field there" do
    farm = needle_hierarchy
    fields = farm.pivots.first.fields
    fields << Field.new(:name => 'another field',:field_capacity => 0.31, :perm_wilting_pt => 0.12)
    farm.save!
    fields.first.destroy
    fields.reload
    assert_equal(1, fields.size, "Should be trimmed by one")
  end
  
  test "can't destroy the only farm in a group" do
    farm = needle_hierarchy
    group = farm.group
    assert_equal(Group, group.class)
    group.farms.each {|f| f.destroy}
    assert_equal(1, group.farms.count,"Should have been unable to destroy the last farm") 
  end
    
  def set_counts
    @farm_count = Farm.count
    @pivot_count = Pivot.count
    @field_count = Field.count
    @fdw_count = FieldDailyWeather.count
  end
  
  def assert_counts(increments={:farm => 0, :pivot => 0, :field => 0, :fdw => 0})
    assert_equal(@farm_count + increments[:farm], Farm.count,'Farm was off')
    assert_equal(@pivot_count + increments[:pivot], Pivot.count,'Pivot was off')
    assert_equal(@field_count + increments[:field], Field.count,'Field was off')
    assert_equal(@fdw_count + increments[:fdw], FieldDailyWeather.count,'FDW count was off')
  end
  
  test "cascading delete still works" do
    farm = needle_hierarchy
    set_counts
    assert_counts
    second_farm = needle_hierarchy("another farm")
    assert_counts(:farm => 1, :pivot => 1, :field => 1, :fdw => FieldDailyWeather::SEASON_DAYS)
    assert(second_farm.destroy,'But I should have been able to clobber it')
    assert_counts
  end
end
