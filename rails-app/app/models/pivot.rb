class Pivot < ActiveRecord::Base
  belongs_to :farm
  has_many :fields
  has_many :irrigation_events
  before_destroy :mother_may_i
  
  after_create :create_new_default_field
  
  @@clobberable = nil
  
  def create_new_default_field
    fields << Field.create(:name => "New field (pivot: #{name})",
      :soil_type_id => SoilType.default_soil_type[:id],
      # try this because we might not be saved and thus the association won't work yet...?
      :pivot_id => self[:id]
      )
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
end
