class Group < ActiveRecord::Base
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :farms, :dependent => :destroy
  has_many :weather_stations
  after_create :make_farm
  
  def make_farm
    # Farm defaults to LaiEtMethod, so we don't have to specify that here
    logger.info "Group#make_farm called"
    farm = Farm.create(:name => 'Farm 1',
      :year => DateTime.now.year, :et_method_id => nil, :group_id => self[:id])
    farm.save!
  end
  
  def destroy_my_hierarchy
    puts "I am making it possible to destroy everything below the group"
    @clobber_farms = true
    self.destroy
  end
  # You can't destroy the only farm in a group. There must always be at least one, unless we're in the process
  # of destroying all the farms in the group
  def may_destroy(farm) 
    @clobber_farms || farms.size > 1
  end
  
end
