class Pivot < ActiveRecord::Base
  belongs_to :farm
  has_many :fields, :dependent => :destroy
  has_many :irrigation_events
  
  after_create :create_new_default_field
  
  def create_new_default_field
    fields << Field.create(:name => "New field (pivot: #{name})",
      # grabbed these numbers from John's spreadsheet
      :field_capacity => 0.31, :perm_wilting_pt => 0.14,
      # try this because we might not be saved and thus the association won't work yet...?
      :pivot_id => self[:id]
      )
  end
end
