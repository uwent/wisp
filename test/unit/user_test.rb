require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  def make_new_user
    arg_hash = {
      :identifier_url => "Hi, I'm an OpenID URL!",
      :email => 'fnord@mailinator.com',
      :first_name => 'first',
      :last_name => 'last'
    }
    user = nil
    assert_nothing_raised(Exception) do
      user = User.new_user(arg_hash)
    end
    user
  end
  
  test "User.new_user works" do
    num_users = User.all.size
    user = make_new_user
    assert(user, "Should have returned a new User object")
    assert_equal(User, user.class,"Should have been a User")
    assert_equal(num_users+1, User.all.size,"There should be a new user in the database")
  end
  
  test "User.new_user creates a group" do
    num_groups = Group.all.size
    make_new_user
    assert_equal(num_groups+1, Group.all.size,"Should have created a new group for the user")
  end
  
  test "user created by User.new_user is a member of the new group" do
    User.destroy_all
    Group.destroy_all
    make_new_user
    group = Group.first
    user = User.first
    assert(user.groups.select { |gr|  gr == group }, "Could not find our group in our groups list")
    assert(group.users.select { |u| u == user }, "Could not find our user in our users list")
  end
  
  test "user is admin of his new group" do
    user = make_new_user
    assert(user.memberships.first.is_admin, "Should be admin of my group!")
  end
end
