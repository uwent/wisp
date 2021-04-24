class ChangeEnergyToString < ActiveRecord::Migration[4.2]
  def change
    change_column :pivots, :some_energy_rate_metric, :string
  end
end
