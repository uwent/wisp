# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create({ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# note that this ID should be the same as AuthenticationHelper.SINGLE_USER_ID 
user = User.create( :id => 1, :email => 'anonymous@mailinator.com', :identifier_url => nil,
   :first_name => 'Anonymous',  :last_name => 'User')

# remaining IDs are set to 1 just as a convenience
group = Group.create(:id => 1, :description => 'Default Group')
membership = Membership.create(:id => 1, :group_id => group[:id], :user_id => user[:id], :is_admin => true)

