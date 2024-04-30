class Crop < ApplicationRecord
  belongs_to :plant, optional: true
  belongs_to :field, optional: true

  before_validation :set_defaults, on: :create

  before_save :update_field_with_emergence_date

  validates :field, presence: true
  validates :plant, presence: true

  def act # placeholder for dummy JSON info, to be replaced by "action" button in grid
    ""
  end

  # Shadows the atttribute -- I'm pulling this out of field/crop setup process and making them put it in on field status
  def initial_soil_moisture
    field.field_capacity * 100.0
  end

  def new_year
    self.emergence_date = Date.civil(Time.now.year, *Field::EMERGENCE_DATE)
    self.harvest_or_kill_date = nil
    save!
  end

  private

  def attributes_that_trigger_field_update
    %w[
      emergence_date
      initial_soil_moisture
      max_allowable_depletion_frac
      max_root_zone_depth
    ]
  end

  def attributes_that_trigger_field_update_changed?
    (changed & attributes_that_trigger_field_update).any?
  end

  def must_update_field?
    attributes_that_trigger_field_update_changed?
  end

  def update_field_with_emergence_date
    return unless must_update_field?

    return unless emergence_date

    field.update_with_emergence_date(emergence_date)
  end

  def set_defaults
    self.name ||= "New crop"
    self.plant ||= Plant.default_plant
    self.max_root_zone_depth ||= plant.default_max_root_zone_depth
    self.variety ||= "A variety"
  end
end
