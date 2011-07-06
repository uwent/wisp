class CreateIrrigationEvents < ActiveRecord::Migration
  def self.up
    create_table :irrigation_events do |t|
      t.integer :pivot_id
      t.date :date
      t.float :inches_applied
      t.float :run_time
      t.float :total_volume

      t.timestamps
    end
  end

  def self.down
    drop_table :irrigation_events
  end
end
