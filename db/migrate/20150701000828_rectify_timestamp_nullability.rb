class RectifyTimestampNullability < ActiveRecord::Migration
  def change
    tables = ActiveRecord::Base.connection.tables - ["schema_migrations"]
    tables_with_timestamps = tables.select do |table|
      ActiveRecord::Base.connection.columns(table).map(&:name).include?('created_at')
    end
    tables_with_timestamps.each do |table|
      change_column table.to_sym, :created_at, :datetime, null: false
      change_column table.to_sym, :updated_at, :datetime, null: false
    end
  end
end
