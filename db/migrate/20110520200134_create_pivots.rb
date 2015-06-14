class CreatePivots < ActiveRecord::Migration
  def self.up
    create_table :pivots do |t|
      t.integer :farm_id
      t.string :name
      t.float :latitude
      t.float :longitude
      t.string :equipment
      t.float :pump_capacity
      t.float :some_energy_rate_metric
      t.integer :cropping_year
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :pivots
  end
end
