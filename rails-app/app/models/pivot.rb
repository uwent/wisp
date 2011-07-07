class Pivot < ActiveRecord::Base
  belongs_to :farm
  has_many :fields
  has_many :irriation_events
  
  after_create :create_new_default_field
  
  def create_new_default_field
    fields << Field.create(:name => 'New field')
  end
end
