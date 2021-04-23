class Group < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :farms, dependent: :destroy
  has_many :pivots, through: :farms
  has_many :fields, through: :pivots
  has_many :weather_stations, dependent: :destroy

  after_create :create_dependent_objects

  def self.farms(group)
    Farm.where(group: group)
  end

  private

  # TODO: this is busted. NoMethodError for create
  def create_dependent_objects
    # farms.create!(name: 'Farm 1', year: Time.now.year)
    Farm.create!(name: 'Farm 1', year: Time.now.year)
  end
end
