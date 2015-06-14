class AddTargetAdToField < ActiveRecord::Migration
  def self.up
    add_column :fields, :target_ad_pct, :float
  end

  def self.down
    remove_column :fields, :target_ad_pct
  end
end