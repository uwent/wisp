class SoilType < ActiveRecord::Base
  DEFAULT_SOIL_TYPE_NAME = 'Sandy Loam'
  def self.default_soil_type
    find_by_name(DEFAULT_SOIL_TYPE_NAME) || first
  end
  
  def self.initial_types
    [
      {:name => 'Sand', :field_capacity => 0.10, :perm_wilting_pt => 0.04},
      {:name => 'Sandy Loam', :field_capacity => 0.15, :perm_wilting_pt => 0.05},
      {:name => 'Loam', :field_capacity => 0.24, :perm_wilting_pt => 0.08},
      {:name => 'Silt Loam', :field_capacity => 0.30, :perm_wilting_pt => 0.16},
      {:name => 'Silt', :field_capacity => 0.31, :perm_wilting_pt => 0.10},
      {:name => 'Clay Loam', :field_capacity => 0.34, :perm_wilting_pt => 0.15},
      {:name => 'Clay', :field_capacity => 0.37, :perm_wilting_pt => 0.20},
    ]
  end
end