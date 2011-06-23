class CreateCrops < ActiveRecord::Migration
  def self.up
    create_table :crops do |t|
      t.integer :field_id
      t.string :crop
      t.string :variety
      t.datetime :emergence_date
      t.datetime :end_date
      t.datetime :harvest_or_kill_date
      t.float :max_root_zone_depth
      t.float :max_allowable_depletion_frac
      t.float :max_allowable_depletion_inches
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :crops
  end
end
