class Pivot < ActiveRecord::Base
  belongs_to :farm
  has_many :fields
  has_many :irriation_events
end
