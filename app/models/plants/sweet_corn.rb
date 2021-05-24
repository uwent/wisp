class SweetCorn < Plant
  # This Plant has a thermally-based LAI model, so it needs degree days
  def uses_degree_days?(et_method)
    et_method == Field::LAI_METHOD
  end

  def lai_for(days_since_emergence, fdw)
    lai_thermal(fdw)
  end
end
