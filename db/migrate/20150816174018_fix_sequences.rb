class FixSequences < ActiveRecord::Migration
  def change
    tables = ActiveRecord::Base.connection.tables - ["schema_migrations"]
    tables.each do |table|
      sql = "SELECT setval('#{table}_id_seq', coalesce(max(id), 0) + 1) FROM #{table}"

      execute(sql)
    end
  end
end
