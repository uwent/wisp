class CreateEtMethods < ActiveRecord::Migration[4.2]
  def self.up
    create_table :et_methods do |t|
      t.string :name
      t.string :description
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :et_methods
  end
end
