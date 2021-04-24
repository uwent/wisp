class AddProviderToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :provider, :string
    add_column :users, :uid, :string
  end

  def self.down
    remove_column :users, :uid
    remove_column :users, :provider
  end
end
