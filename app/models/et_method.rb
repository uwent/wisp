require 'et_calculator' # Does it really need this? Shouldn't, should it?

class EtMethod < ActiveRecord::Base
  has_many :farms
  include ETCalculator
  def adj_et(day)
    raise "Generic ET method can't calculate anything!"
  end
end

class PctCoverEtMethod < EtMethod
  def adj_et(day)
    if day.respond_to?(:ref_et) then ref_et = day.ref_et else ref_et = day[:ref_et] end
    if day.respond_to?(:pct_cover) then pct_cover = day.pct_cover else pct_cover = day[:pct_cover] end
    adjETPctCover(ref_et,pct_cover)
  end
end

class LaiEtMethod < EtMethod
  def adj_et(day)
    raise "LAI ET Method not yet implemented"
  end
end