class Crop < ActiveRecord::Base
  belongs_to :field
  after_save :update_field_with_emergence_date
  # validates :field, :presence => true
  
  def update_field_with_emergence_date
    if emergence_date
      # puts "updating our field's canopy (#{field[:id]})"
      field.update_canopy(emergence_date)
    end
  end
end
