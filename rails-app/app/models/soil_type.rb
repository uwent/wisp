class SoilType < ActiveRecord::Base
  def self.default_soil_type
    find_by_name('Sandy Loam') || first
  end
end
