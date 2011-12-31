# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create({ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
require File.join(File.dirname(__FILE__),'..','app','models','et_method')
pct_cover_id = PctCoverEtMethod.create(:name => "Percent Cover", :description => "Uses regressions derived with WI A3600 tables")[:id]
lai_id = LaiEtMethod.create(:name => "Leaf Area Index", :description => "Uses LAI measurements and to derive a crop coefficient")[:id]

# note that this ID should be the same as AuthenticationHelper.SINGLE_USER_ID 
user = User.create!( :id => 1, :email => 'anonymous@mailinator.com', :identifier_url => nil,
   :first_name => 'Anonymous',  :last_name => 'User')

# remaining IDs are set to 1 just as a convenience
group = Group.create(:id => 1, :description => 'Default Group')
membership = Membership.create(:id => 1, :group_id => group[:id], :user_id => user[:id], :is_admin => true)
farm = Farm.create(:id => 1, :name => 'Default Farm', :group_id => group[:id], :year => Time.now.year, :et_method_id => lai_id)

SoilType.create(:name => 'Sand', :field_capacity => 0.10, :perm_wilting_pt => 0.04)
SoilType.create(:name => 'Sandy Loam', :field_capacity => 0.15, :perm_wilting_pt => 0.05)
SoilType.create(:name => 'Loam', :field_capacity => 0.24, :perm_wilting_pt => 0.08)
SoilType.create(:name => 'Silt Loam', :field_capacity => 0.30, :perm_wilting_pt => 0.16)
SoilType.create(:name => 'Silt', :field_capacity => 0.31, :perm_wilting_pt => 0.10)
SoilType.create(:name => 'Clay Loam', :field_capacity => 0.34, :perm_wilting_pt => 0.15)
SoilType.create(:name => 'Clay', :field_capacity => 0.37, :perm_wilting_pt => 0.20)
