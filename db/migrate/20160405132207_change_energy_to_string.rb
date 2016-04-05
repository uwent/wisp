class ChangeEnergyToString < ActiveRecord::Migration
  def change
    change_column :pivots, :some_energy_rate_metric, :string
  end
end
