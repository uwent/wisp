class CreateWeatherStations < ActiveRecord::Migration
  def self.up
    create_table :weather_stations do |t|
      t.integer :group_id
      t.string :name
      t.string :location
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :weather_stations
  end
end
