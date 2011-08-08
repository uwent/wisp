# Calculates adjusted evapotranspiration (hereinafter ET) from a "reference ET" number and other stuff like
# percent canopy cover or leaf-area index.
# Created:: 31May2011
# Authors:: P Kaarakka, Rick Wayne

module ETCalculator
  
 # Originally these were class methods, but it turns out to make more sense to use "include" in a class
 # and make then instance methods of that class; ADCalculator is the same way.
 
  # Return the adjusted ET. Uses regression coefficients derived by J. Panuska from the UW Extension pub A3600.
  def adj_et_pct_cover(refET,pctCover)
    # regression coefficients from J. Panuska in Linear_Regressions_for_A3600_Table.doc and based on Table C of UW Extension pub A3600, "Irrigation Management in Wisconsin - the Wisconsin Irrigation Scheduling Program (WISP)" 
    coeff = [[0,0],[-0.002263,0.2377],[-0.002789,0.3956],[-0.002368,0.5395],[-0.000316,0.6684],[-0.000053,0.7781],[0.001053,0.8772],[0.001947,0.9395],[0.000000,1.000]]
  
    #NOTE: coeffIndex and interpolations assume pctCover curves are all exactly 10% apart. 
    coeffIndex = (pctCover/10).floor
    case coeffIndex
      when 0  # Get zero %cover adjET
        case refET
		  when 0.0 
			return 0.0	
          when 0..0.159
            adjETLow = 0.0
          when 0.160..0.319
            adjETLow = 0.010
          else 
            adjETLow = 0.020
        end
        # Get 10 %cover adjET
        adjETHigh = coeff[1][0] + refET*coeff[1][1]
        # Interpolate adjET between zero and 10 %cover
        adjET = adjETLow + ((pctCover/10)*(adjETHigh-adjETLow))

      when 1..7  # Get low end adjET
        adjETLow  = coeff[coeffIndex][0] + refET*coeff[coeffIndex][1]  
        # Get high end adjET
        adjETHigh = coeff[coeffIndex+1][0] + refET*coeff[coeffIndex+1][1]
        # Interpolate adjET between low and high %cover
        adjET = adjETLow + (((pctCover - coeffIndex*10)/10) * (adjETHigh-adjETLow))

      else     # At 80% cover and above there is no adjustment to the refET
        adjET = refET
    end
    return adjET
  end #adj_et_pct_cover

  # LAI growth curve function for corn from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def calc_lai_corn(days_since_emergence)
	(0.000000000009*(days_since_emergence)**7.95)*(Math.exp(-0.1*(days_since_emergence)))
  end
  
  # Return adjusted ET from the reference ET and the days sinçe emergence
  # Crop coeff math is from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def adj_et_lai_corn(refET,days_since_emergence)
	crop_coeff = 1.1*(1-Math.exp(-1.5*(calc_lai_corn(days_since_emergence))))
	adjET = refET * crop_coeff
  end

  # Return adjusted ET from the reference ET if the leaf area index is already in hand
  # Crop coeff math is from WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
  def adj_et_from_lai_corn(refET,lai)
	crop_coeff = 1.1*(1-Math.exp(-1.5*(lai)))
	adjET = refET * crop_coeff
  end

  # Duck Typing at work here; "day" can be anything that responds to the methods "refET", "lai", and "pctCover".
  # So an ActiveRecord class instance with those table columns will work, or a mock object for testing,
  # or wrapper around some other class that calls them referenceET and leafAreaIndex.
  # This is a function returning the adjusted ET; it makes use of Ruby's "last-executed statement" return
  # value feature to avoid having to initialize a variable and explicitly return it
  def calc_adj_ET(day)
    # look at LAI first; since pctCover is (???) more likely to have default values automatically calculated,
    # if LAI is present it means the user wants us to use it
    if day.leaf_area_index
      adj_et_from_lai_corn(day.refET,day.leaf_area_index)
    else
      adj_et_pct_cover(day.refET,day.pctCover)
    end
  end
  
  # In addition to the four methods expected above for "day", this one expects "day" to have a
  # adjET=(et_value) method
  def update_adj_et_single_day(day)
    day.adjET =  calc_ad_ET(day)
  end
  
end # module EtCalculator
