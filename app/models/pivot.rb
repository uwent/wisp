class Pivot < ApplicationRecord
  belongs_to :farm, optional: true
  has_many :fields, dependent: :destroy
  has_many :crops, through: :fields
  has_many :irrigation_events, dependent: :destroy

  before_validation :set_defaults, on: :create

  after_create :create_dependent_objects

  attr_accessor :cloning

  # placeholder for dummy JSON info, to be replaced by "action" button in grid
  def act
    ""
  end

  def problem
    fields.select do |field|
      field.problem
    end
  end

  def new_year
    return if cropping_year == Time.now.year
    self.irrigation_events = []
    self.cropping_year = Time.now.year
    save!
    fields.each { |f| f.new_year }
  end

  private

  def set_defaults
    self.name ||= farm ? "New Pivot #{farm.pivots.size + 1}" : "New Pivot"
    self.cropping_year ||= Time.now.year
    self.latitude ||= 43
    self.longitude ||= -89
    self.some_energy_rate_metric = "Electric"
  end

  def create_dependent_objects
    return if fields.any? || cloning
    fields.create!
  end
end
