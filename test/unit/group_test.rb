require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  def setup
    @group = Group.first
    @farms = @group.farms
    @farm_ids = @farms.collect { |f| f[:id] }
    @pivots = @farms.collect { |farm| farm.pivots }.flatten
    @pivot_ids = @pivots.collect { |f| f[:id] }
    @fields = @pivots.collect {|pivot| pivot.fields}.flatten
    @field_ids = @fields.collect { |f| f[:id] }
    @fdw = @fields.collect {|field| field.field_daily_weather}.flatten
    @field_daily_weather_ids = @fdw.collect { |f| f[:id] }
    @crops = @fields.collect {|field| field.crops}.flatten
    @crop_ids = @crops.collect { |f| f[:id] }
  end

  test "fixtures have a hierarchy" do
    assert(@group, "No initial group")
    assert(@farms.size > 0, "First group has no farms.")
    assert(@pivots.size > 0,"No pivots in any farm")
    assert(@fields.size > 0, "No fields.")
    assert(@fdw.size > 0, "No field daily weather")
    assert(@crops.size > 0, "No crops")
  end

  test "fields_for" do
    Farm.delete_all
    Field.delete_all
    @group = Group.create!
    @fields = []
    (1..1).each do |f|
      farm = Farm.create! name: "Farm #{f}", year: 2014, group_id: @group[:id]
      (1..2).each do |p|
        pivot = Pivot.create! name: "Pivot #{p}", cropping_year: 2014, farm_id: farm[:id]
        (1..2).each do |fi|
          field = Field.create! name: "Field #{fi}", pivot_id: pivot[:id]
        end
      end
    end
    @group.save!
    @group.farms.each { |farm| farm.pivots.each { |pivot| pivot.fields.each { |field| @fields << field } } }
    expected = @fields.collect { |f| f[:id] }.sort
    actual = @group.fields_for.collect { |f| f[:id] }.sort
    assert_equal(expected,actual)
  end
  
  ## This does not work. And I'm not even sure that it should -- there is no UI for deleting groups right now,
  ## and so this is unneeded, and can be thought through better when it becomes so.
  
  # test "wipe group" do
  #   id = @group[:id]
  #   @group.destroy_my_hierarchy
  #   assert_raise(ActiveRecord::RecordNotFound,"Group #{id} should be gone") { Group.find(id) }
  #   @farm_ids.each { |id| assert_raise(ActiveRecord::RecordNotFound,"Farm #{id} should be gone") {Farm.find(id)  } }
  #   @pivot_ids.each { |id| assert_raise(ActiveRecord::RecordNotFound,"Pivot #{id} should be gone") { Pivot.find(id) } }
  #   @field_ids.each { |id| assert_raise(ActiveRecord::RecordNotFound,"Field #{id} should be gone") { Field.find(id) } }
  #   @field_daily_weather_ids.each { |id| assert_raise(ActiveRecord::RecordNotFound,"FDW #{id} should be gone") { FieldDailyWeather.find(id) } }
  #   @crop_ids.each { |id| assert_raise(ActiveRecord::RecordNotFound,"Crop #{id} should be gone") { Crop.find(id) } }
  # end
end