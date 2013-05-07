class EtMethod < ActiveRecord::Base
  has_many :farms
  include ETCalculator
  def adj_et(day)
    raise "Generic ET method can't calculate anything!"
  end
  def method_name
    raise "Generic ET method has no name!"
  end
end

class PctCoverEtMethod < EtMethod
  def adj_et(day)
    if day.respond_to?(:ref_et) then ref_et = day.ref_et else ref_et = day[:ref_et] end
    if day.respond_to?(:pct_cover) then pct_cover = day.pct_cover else pct_cover = day[:pct_cover] end
    adj_et_pct_cover(ref_et,pct_cover)
  end
  def method_name
    "PctCover"
  end
end

class LaiEtMethod < EtMethod
  def adj_et(day)
    return nil unless day.ref_et && day.leaf_area_index
    adj_et_from_lai_corn(day.ref_et,day.leaf_area_index)
  end
  def method_name
    "LAI"
  end
end