require 'owned'

class Crop < ActiveRecord::Base
  include Owned
  belongs_to :field
  after_save :update_field_with_emergence_date
  # Only go through the painful process of updating the canopy and recalcing all balances if needed
  attr_accessor :dont_update_canopy
  # validates :field, :presence => true
  
  # Do we really need to update the canopy?
  def must_update_canopy?(attribs)
    # puts attribs.inspect; $stdout.flush
    # puts self.inspect; $stdout.flush
    [:emergence_date, :max_root_zone_depth, :max_allowable_depletion_frac,
      :initial_soil_moisture].each do |attrib_name|
      if self[attrib_name].to_s != attribs[attrib_name].to_s
        return true
      end
    end
    return false
  end
  
  def do_attribs(attribs)
    # Check if we can skip the painfully long canopy update
    @dont_update_canopy = !(must_update_canopy?(attribs))
    update_attributes(attribs)
    @dont_update_canopy = true
    # puts "done updating"; $stdout.flush
  end
  
  def update_field_with_emergence_date
    unless @dont_update_canopy || !(emergence_date)
      # puts "updating our field's canopy (#{field[:id]})"; $stdout.flush
      field.update_canopy(emergence_date)
      # logger.info "************************************* update canopy finished *****************"
    end
  end
  
  # Implement the Owned interface
  def owner
    field.pivot.farm.group
  end
end
