class CropsHavePlants < ActiveRecord::Migration
  def self.up
    add_column :crops, :plant_id, :integer
  end

  def self.down
    remove_column :crops, :plant_id
  end
end
