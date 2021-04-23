class CropsAddInitialSoilMoisture < ActiveRecord::Migration[4.2]
  def self.up
    add_column :crops, :initial_soil_moisture, :float
  end

  def self.down
    remove_column :crops, :initial_soil_moisture
  end
end
