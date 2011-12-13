# Calculates adjusted evapotranspiration (hereinafter ET) from a "reference ET" number and other stuff like
# percent canopy cover or leaf-area index.
# Created:: 31May2011
# Authors:: P Kaarakka, Rick Wayne

module ETCalculator
  
 # Originally these were class methods, but it turns out to make more sense to use "include" in a class
 # and make then instance methods of that class; ADCalculator is the same way.
 
  # Return the adjusted ET. Uses regression coefficients derived by J. Panuska from the UW Extension pub A3600.
  def adj_et_pct_cover(ref_et,pctCover)
    # regression coefficients from J. Panuska in Linear_Regressions_for_A3600_Table.doc and based on Table C of UW Extension pub A3600, "Irrigation Management in Wisconsin - the Wisconsin Irrigation Scheduling Program (WISP)" 
    coeff = [[0,0],[-0.002263,0.2377],[-0.002789,0.3956],[-0.002368,0.5395],[-0.000316,0.6684],[-0.000053,0.7781],[0.001053,0.8772],[0.001947,0.9395],[0.000000,1.000]]
  
    #NOTE: coeffIndex and interpolations assume pctCover curves are all exactly 10% apart. 
    coeffIndex = (pctCover/10).floor
    case coeffIndex
      when 0  # Get zero %cover adj_et
        case ref_et
      when 0.0 
      return 0.0  
          when 0..0.159
            adj_etLow = 0.0
          when 0.160..0.319
            adj_etLow = 0.010
          else 
            adj_etLow = 0.020
        end
        # Get 10 %cover adj_et
        adj_etHigh = coeff[1][0] + ref_et*coeff[1][1]
        # Interpolate adj_et between zero and 10 %cover
        adj_et = adj_etLow + ((pctCover/10)*(adj_etHigh-adj_etLow))

      when 1..7  # Get low end adj_et
        adj_etLow  = coeff[coeffIndex][0] + ref_et*coeff[coeffIndex][1]  
        # Get high end adj_et
        adj_etHigh = coeff[coeffIndex+1][0] + ref_et*coeff[coeffIndex+1][1]
        # Interpolate adj_et between low and high %cover
        adj_et = adj_etLow + (((pctCover - coeffIndex*10)/10) * (adj_etHigh-adj_etLow))

      else     # At 80% cover and above there is no adjustment to the ref_et
        adj_et = ref_et
    end
    return adj_et
  end #adj_et_pct_cover

  # LAI growth curve function for corn from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def lai_corn(days_since_emergence)
  (0.000000000009*(days_since_emergence)**7.95)*(Math.exp(-0.1*(days_since_emergence)))
  end
  
  # Return adjusted ET from the reference ET and the days sinçe emergence
  # Crop coeff math is from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def adj_et_lai_corn(ref_et,days_since_emergence)
  crop_coeff = 1.1*(1-Math.exp(-1.5*(lai_corn(days_since_emergence))))
  adj_et = ref_et * crop_coeff
  end

  # Return adjusted ET from the reference ET if the leaf area index is already in hand
  # Crop coeff math is from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def adj_et_from_lai_corn(ref_et,lai)
  crop_coeff = 1.1*(1-Math.exp(-1.5*(lai)))
  adj_et = ref_et * crop_coeff
  end

  # Duck Typing at work here; "day" can be anything that responds to the methods "ref_et", "lai", and "pctCover".
  # So an ActiveRecord class instance with those table columns will work, or a mock object for testing,
  # or wrapper around some other class that calls them referenceET and leafAreaIndex.
  # This is a function returning the adjusted ET; it makes use of Ruby's "last-executed statement" return
  # value feature to avoid having to initialize a variable and explicitly return it
  def calc_adj_ET(day)
    # look at LAI first; since pctCover is (???) more likely to have default values automatically calculated,
    # if LAI is present it means the user wants us to use it
    # This is a bug -- the mere presence of a number here shouldn't be used to drive this. For now, just assume LAI.
    if day.leaf_area_index
      adj_et_from_lai_corn(day.ref_et,day.leaf_area_index)
    else
      adj_et_pct_cover(day.ref_et,day.pct_cover)
    end
  end
  
  # In addition to the four methods expected above for "day", this one expects "day" to have a
  # adj_et=(et_value) method
  def update_adj_et_single_day(day)
    day.adj_et =  calc_adj_ET(day)
  end
  
  #
  # Percent Cover methods
  #
  def find_entered_pct_covers(wx_arr)
    res = []
    day = 0
    wx_arr.each do |weather_day|
      if weather_day.respond_to?('[]') && (pc = weather_day[:entered_pct_cover])
        res << {day => pc}
      end
      day += 1
    end
    res
  end
  
  def linear_increment(start_val,finish_val,n_vals)
    (finish_val - start_val) / (n_vals - 1)
  end
  
  
  def apply_increment(wx_arr,start_val,increment,n_vals)
    (0..n_vals).each do |ii|
      
    end
  end
  
  def interpolate_pct_cover(wx_arr)
    entered_pts = find_entered_pct_covers(wx_arr)
    # If no points have been entered, nothing to interpolate
    return unless entered_pts.size > 0
    if entered_pts.size == 1 # so, something like [{day => pct_cover}]
      # If there's only one entered point, if it's the first one we got nothin'!
      return if entered_pts[0].keys.first == 0
    end
    # Add zero for the first day's value if none was explicitly entered
    unless entered_pts[0].keys.first == 0
      entered_pts = [{0 => 0.0}] + entered_pts
    end

    (0..entered_pts.size-2).each do |ii|
      first = entered_pts[ii]
      first_day = first.keys.first # there's only one
      first_val = first[first_day] # the value for that day
      second = entered_pts[ii+1]
      second_day = second.keys.first
      second_val = second[second_day]
      incr = linear_increment(first_val,second_val,1+second_day - first_day)
      val = first_val
      # Note that this sets the calculated_pct_cover fields of the days with entered_pct_cover,
      # but should be to the same value
      (first_day..second_day).each do |ii|
        wx_arr[ii][:calculated_pct_cover] = val
        val += incr
        if wx_arr[ii].respond_to?('save!')
          wx_arr[ii].save!
        end
      end
    end
  end
  
end # module EtCalculator
