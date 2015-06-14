class CreateFields < ActiveRecord::Migration
  def self.up
    create_table :fields do |t|
	  t.string :name
      t.integer :soil_type
      t.float :area
      t.float :field_capacity
      t.float :perm_wilting_pt
      t.integer :pivot_id
      t.integer :ref_et_station_id
      t.integer :rain_station_id
      t.integer :soil_moisture_station_id
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :fields
  end
end
