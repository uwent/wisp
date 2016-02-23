class EnforceCroppiingYearOnPivots < ActiveRecord::Migration
  def change
    execute('update pivots set cropping_year = extract(year from now()) where cropping_year is null')

    change_column_null :pivots, :cropping_year, false
  end
end
