class Group < ActiveRecord::Base
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :farms
  has_many :weather_stations
  after_create :make_farm
  
  def make_farm
    # Farm defaults to LaiEtMethod, so we don't have to specify that here
    logger.info "Group#make_farm called"
    farm = Farm.create(:name => 'Farm 1',
      :year => DateTime.now.year, :et_method_id => nil, :group_id => self[:id])
    farm.save!
  end
  
  
  # You can't destroy the only farm in a group. There must always be at least one.
  def may_destroy(farm) 
    farms.size > 1
  end
  
end
