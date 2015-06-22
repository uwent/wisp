class Pivot < ActiveRecord::Base
  belongs_to :farm
  has_many :fields, dependent: :destroy
  has_many :irrigation_events, dependent: :destroy

  before_save :set_cropping_year
  before_destroy :mother_may_i

  after_create :create_dependent_objects

  @@clobberable = nil

  def set_cropping_year
    self.cropping_year ||= Time.now.year
  end

  def create_dependent_objects
    fields.create!(
      name: "New field (Pivot ID: #{id})",
      soil_type_id: SoilType.default_soil_type.id)
  end

  def mother_may_i
    if farm.may_destroy(self)
      @@clobberable = id
      Field.destroy_all "pivot_id = #{id}"
      return true
    else
      return false
    end
  end

  def may_destroy(field)
    fields.size > 1 || @@clobberable == id
  end

  def act # placeholder for dummy JSON info, to be replaced by "action" button in grid
    ""
  end

  def problem
    fields.inject([]) {|problems,field| problems << field if field.problem; problems }
  end

  def clone_for(year=Time.now.year)
    return nil if cropping_year == year # Can't clone to same year
    new_attrs = {}
    attributes.each { |key,val| new_attrs[key] = val unless key == :id || key == 'id' }
    new_attrs[:cropping_year] = year
    new_piv = Pivot.create(new_attrs)
    dead_field_walking = new_piv.fields.first
    fields.each do |field|
      f_attrs = field.attributes
      f_attrs.delete(:id)
      f_attrs[:pivot_id] = new_piv[:id]
      Field.create(f_attrs)
    end
    # Now delete the automatically-created one
    fields.delete(dead_field_walking)
    dead_field_walking.destroy
    new_piv
  end
end
