class CreateWeatherStationData < ActiveRecord::Migration
  def self.up
    create_table :weather_station_data do |t|
      t.integer :station_id
      t.date :date
      t.float :ref_et
      t.float :rainfall
      t.float :soil_moisture
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :weather_station_data
  end
end
