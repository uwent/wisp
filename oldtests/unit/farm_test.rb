require "test_helper"

class FarmTest < ActiveSupport::TestCase
  CROPPING_YEAR = 2012
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
    assert_equal(@ricks_farms, my_farms, "my_farms should return the same farms as ricks_group")
  end

  def needle_hierarchy(name = "A farm")
    group_id = Group.first[:id]
    farm = Farm.new(name: name, year: CROPPING_YEAR, group_id: group_id)
    farm.save!
    farm
  end

  test "can create the one-element-per-level hierarchy" do
    assert(farm = needle_hierarchy, "what, I can't create a farm?")
    assert_equal(Farm, farm.class, "It should have been a Farm")
    assert_equal(1, farm.pivots.size, "Farms come with pivots by default, don't they?")
    assert_equal(1, farm.pivots.first.fields.size, "and pivots make a field, too")
  end

  test "can't destroy the only field" do
    farm = needle_hierarchy
    fields = farm.pivots.first.fields
    result = fields.first.destroy
    fields.reload
    assert_equal(1, fields.size, "Should have been unable to destroy it")
  end

  test "can destroy if more than one field there" do
    farm = needle_hierarchy
    fields = farm.pivots.first.fields
    fields << Field.new(name: "another field", field_capacity: 0.31, perm_wilting_pt: 0.12)
    farm.save!
    fields.first.destroy
    fields.reload
    assert_equal(1, fields.size, "Should be trimmed by one")
  end

  test "can't destroy the only farm in a group" do
    farm = needle_hierarchy
    group = farm.group
    assert_equal(Group, group.class)
    group.farms.each { |f| f.destroy }
    assert_equal(1, group.farms.count, "Should have been unable to destroy the last farm")
  end

  def set_counts
    @farm_count = Farm.count
    @pivot_count = Pivot.count
    @field_count = Field.count
    @fdw_count = FieldDailyWeather.count
  end

  def assert_counts(increments = {farm: 0, pivot: 0, field: 0, fdw: 0})
    assert_equal(@farm_count + increments[:farm], Farm.count, "Farm was off")
    assert_equal(@pivot_count + increments[:pivot], Pivot.count, "Pivot was off")
    assert_equal(@field_count + increments[:field], Field.count, "Field was off")
    assert_equal(@fdw_count + increments[:fdw], FieldDailyWeather.count, "FDW count was off")
  end

  test "cascading delete still works" do
    farm = needle_hierarchy
    set_counts
    assert_counts
    second_farm = needle_hierarchy("another farm")
    assert_counts(farm: 1, pivot: 1, field: 1, fdw: FieldDailyWeather::SEASON_DAYS)
    assert(second_farm.destroy, "But I should have been able to clobber it")
    assert_counts
  end

  test "clone_pivots_for works" do
    farm = needle_hierarchy
    this_year = Time.now.year
    assert_nothing_raised(NoMethodError) { farm.clone_pivots_for }
  end

  test "clone_pivots_for doubles the number of pivots" do
    farm = needle_hierarchy
    assert_difference "farm.pivots.size", farm.pivots.size do
      farm.clone_pivots_for
    end
  end

  def inspect_pivots(pivots)
    pivots.collect { |p| "#{p.name}: #{p.cropping_year}, farm #{p.farm_id}" }.join("\n")
  end

  test "can select the set of latest pivots for an array of farms" do
    farm_w_recent_pivot_iis = [1, 3]
    farm = needle_hierarchy
    group = farm.group
    4.times do |n|
      group.farms << Farm.create(group_id: group[:id], name: "CY farm #{n}", year: CROPPING_YEAR) # So it has one pivot with CROPPING YEAR
    end
    group.save!
    farm_w_recent_pivot_iis.each do |ii|
      f = group.farms[ii]
      f.pivots << Pivot.create(farm_id: f[:id], cropping_year: CROPPING_YEAR + 1, name: "pick me #{ii}")
    end
    # Now we should have a group of 5 farms, each with one pivot whose cropping year is CROPPING_YEAR.
    # In addition, group.farms[1] and group.farms[3] should also have a pivot whose cropping year is CROPPING_YEAR + 1,
    # and whose names are "pick me 1" and "pick me 3", respectively.
    recent_pivots = Farm.latest_pivots(group.farms)
    assert_equal(Array, recent_pivots.class)
    assert_equal(farm_w_recent_pivot_iis.size, recent_pivots.size, inspect_pivots(recent_pivots))
    recent_pivots.each { |p|
      assert_equal(CROPPING_YEAR + 1, p.cropping_year)
      assert_equal(0, p.name =~ /^pick me [#{farm_w_recent_pivot_iis.join('')}]$/, "#{inspect_pivots(recent_pivots)}, pivot name was #{p.name}")
    }
  end
end
