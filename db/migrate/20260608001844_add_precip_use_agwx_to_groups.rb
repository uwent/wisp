class AddPrecipUseAgwxToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :precip_use_agwx, :boolean, default: true, null: false
  end
end
