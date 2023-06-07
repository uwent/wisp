require "test_helper"

class FarmsControllerTest < ActionController::TestCase
  setup do
    @farm = farms(:ricks_other_farm)
    @rick = users(:rick)
    session[:user_id] = @rick[:id]
    assert(@rick.memberships.size > 0, "Rick should have memberships")
    @rick.memberships.each { |m| assert(m.group, "Each of Rick's memberships should have a group too") }
    @prev_years = @farm.pivots.collect { |p| p.cropping_year }
    @prev_years.each { |y| assert(y < Time.now.year) }
  end

  test "check_year_for_cloning gets called" do
    get :index
    assert(assigns(:pivots_need_cloning), "Should always set @pivots_need_cloning")
  end

  test "nonzero number of pivots should need cloning" do
    get :index
    pnc = assigns(:pivots_need_cloning)
    assert_equal(Array, pnc.class)
    assert(pnc.size > 0, "Should have been pivots needed to clone!")
  end
end
