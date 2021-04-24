class Pivot < ApplicationRecord
  belongs_to :farm, optional: true
  has_many :fields, dependent: :destroy
  has_many :crops, through: :fields
  has_many :irrigation_events, dependent: :destroy

  before_validation :set_defaults, on: :create

  after_create :create_dependent_objects

  attr_accessor :cloning

  def act # placeholder for dummy JSON info, to be replaced by "action" button in grid
    ""
  end

  # TODO: Remove, this appears unused.
  # def problem
  #   fields.select do |field|
  #     field.problem
  #   end
  # end

  # FIXME: Remove this.
  # def clone_for(year=Time.now.year)
  #   return if cropping_year == year # Can't clone to same year

  #   new_pivot = self.dup
  #   new_pivot.cropping_year = year
  #   new_pivot.cloning = true

  #   transaction do
  #     new_pivot.save!

  #     fields.each do |field|
  #       new_field = field.dup
  #       new_field.pivot = new_pivot
  #       new_field.save!
  #     end

  #     self.destroy!
  #   end

  #   new_pivot
  # end

  def new_year
    return if self.cropping_year == Time.now.year
    self.irrigation_events = []
    self.cropping_year = Time.now.year
    self.save!
    self.fields.each { | f | f.new_year }
  end

  private

  def set_defaults
    self.name ||= "New pivot (farm ID: #{farm_id})"
    self.cropping_year ||= Time.now.year
  end

  def create_dependent_objects
    return if fields.any? || cloning

    fields.create!
  end
end
