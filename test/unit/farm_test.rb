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
end
