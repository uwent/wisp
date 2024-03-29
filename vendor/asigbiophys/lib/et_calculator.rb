# Calculates adjusted evapotranspiration (hereinafter ET) from a "reference ET" number 
# and other stuff like percent canopy cover or leaf-area index.
# Created:: 31May2011
# Authors:: P Kaarakka, Rick Wayne

module ETCalculator
  
 # Originally these were class methods, but it turns out to make more sense to use "include" in a class
 # and make then instance methods of that class; ADCalculator is the same way.

  # GENERIC METHODS (for both LAI and percent cover)  

  # Duck Typing at work here; "day" can be anything that responds to the methods:
  # "et_method", "ref_et", "leaf_area_index", and "pct_cover".
  # So an ActiveRecord class instance with those table columns will work, or a mock object for testing,
  # or wrapper around some other class that calls them referenceET and leafAreaIndex.
  def calc_adj_ET(day)
    if day.respond_to?('et_method')
      day.et_method.adj_et(day)
    else
      raise "Can't get ET method"
    end
  end

  # In addition to the four methods expected above for "day", this one expects "day" to have a
  # adj_et=(et_value) method
  def update_adj_et_single_day(day)
    day.adj_et =  calc_adj_ET(day)
  end

 
  #
  # LAI
  #
  
  # LAI GROWTH CURVE MODELS
  
  # LAI growth curve function for corn from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def lai_corn(days_since_emergence)
    (0.000000000009*(days_since_emergence)**7.95)*(Math.exp(-0.1*(days_since_emergence)))
  end
  
  # def self.generate_growth_curve
  #   # y = -8E-19x6 + 3E-15x5 + 2E-12x4 - 2E-08x3 + 2E-05x2 - 0.003x + 0.0577
  #   # R² = 0.9971
  # -8E-19x6 + 3E-15x5 + 2E-12x4 - 2E-08x3 + 2E-05x2 - 0.003x + 0.0577
  # = -3E-06x2 + 0.0073x - 0.6728
  # end
  
  # Return the LAI for a given day. "day" must be something with a "degree_days" method.
  # We can have a number of these, one for each plant whose growth curve has been established.
  def lai_thermal(day)
    fake_lai_thermal(day.degree_days)
  end
  
  # This is a placeholder function until we get some real data.
  def fake_lai_thermal(dd)
    (-0.000003 * dd * dd) + (0.0073 * dd) - 0.6728 if dd
  end
  
  # LAI ADJUSTED ET CALCS
  
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

  # This is just copied straight from lai_corn, but makes the API a little more generic.
  def adj_et_lai_for_nonclumping(ref_et,lai)
    crop_coeff = 1.1*(1-Math.exp(-1.5*(lai)))
    adj_et = ref_et * crop_coeff
  end
  
  def adj_et_lai_for_clumping(ref_et,lai)
    
  end
  
  #
  # Percent Cover methods
  #
  # Percent cover calcs don't have a growth-curve generator, there's just the adjusted-ET equation.
  #
  # Return the adjusted ET. Uses regression coefficients derived by J. Panuska from the UW Extension pub A3600.
  def adj_et_pct_cover(ref_et,pctCover)
    ref_et ||= 0.0 #if ref_et == nil #pk 6/3/14
    pctCover ||= 0.0 #if pctCover == nil #pk 6/3/14
    return 0.0 if ref_et < 0.000001 #Does the limit need to be bigger to be effective? pk 6/3/14
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
        adj_et = adj_etLow + (((pctCover - coeffIndex*10)/10) *(adj_etHigh-adj_etLow))

      else     # At 80% cover and above there is no adjustment to the ref_et
        adj_et = ref_et
    end
    return adj_et
  end #adj_et_pct_cover

  def surrounding(wx_arr,middle,parameter)
    max_index = wx_arr.size - 1
    return nil if max_index < 2 || middle > max_index || middle < 0
    res = [0,max_index]
    if middle > 0
      (middle - 1).downto(0) do |ii|
        if wx_arr[ii].respond_to?('[]') && (wx_arr[ii][parameter])
          res[0] = ii
          break
        end
      end
    end
    if middle < max_index
      (middle + 1).upto(max_index) do |ii|
        if wx_arr[ii].respond_to?('[]') && (wx_arr[ii][parameter])
          res[1] = ii
          break
        end
      end
    end
    res
  end
  
  def linear_increment(start_val,finish_val,n_vals)
    (finish_val - start_val) / (n_vals - 1)
  end
  
  def linear_interpolation(wx_arr,start,finish,entered_method,calc_method)
    return unless wx_arr && wx_arr.size > 2 # Can't interpolate nothin', or if arr has fewer than 3 values
    return unless (n_vals = 1 + finish - start) > 1 # Finish and start have to be far enough apart
    return if start >= finish && start < 0 && finish > wx_arr.size - 1
    start_val = wx_arr[start][entered_method] || wx_arr[start][calc_method] || 0.0
    finish_val = wx_arr[finish][entered_method] || wx_arr[finish][calc_method] || 0.0
    
    #if finish_val >= harvest/kill date then %cover should be decaying to zero unless a second crop is growing. pk 12Aug14
    
    incr = linear_increment(start_val,finish_val,n_vals)
    start.upto(finish).each do |ii|
      # Note that this sets the calculated_pct_cover fields of the days with entered_pct_cover,
      # but should be to the same value
      wx_arr[ii][calc_method] = start_val + (ii - start)*incr
      if wx_arr[ii].respond_to?('save!')
        begin
          wx_arr[ii].save!
        rescue Exception => e
          dbg = <<-END
          ETCalculator::linear_interpolation: Could not save wx_arr[#{ii}]
            start #{start} finish #{finish} entered_method #{entered_method} calc_method #{calc_method}
            start_val #{start_val} finish_val #{finish_val} incr #{incr}
            #{wx_arr[ii].inspect}
          END
          logger.warn dbg
        end
      end
    end
  end
  
end # module EtCalculator
