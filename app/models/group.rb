class Group < ActiveRecord::Base
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :farms, dependent: :destroy
  has_many :pivots, through: :farms
  has_many :fields, through: :pivots
  has_many :weather_stations, dependent: :destroy

  after_create :create_dependent_objects

  private

  def create_dependent_objects
    farms.create!(name: 'Farm 1', year: Time.now.year)
  end
end
