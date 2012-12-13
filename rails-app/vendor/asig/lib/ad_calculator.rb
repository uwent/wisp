module ADCalculator
  # Calculations for all one-time and daily water balance parameters.
  # These calculations just return the calculated value and assume that
  # some other code is responsible for stuffing the results into the appropriate storage.
  # These are all instance methods now, which obviates the necessity for callers to do
  # ADCalculator::method.
  # Authors:: Paul Kaarakka, Rick Wayne

  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # This should be recalculated and saved whenever soils, crop, or root zone depth are changed
  # TAW is Total Available Water
  # fc is field capacity
  # pwp is permanent wilting point
  # mrzd is managed root zone depth
  # Result is inches of water
  def taw(fc, pwp, mrzd)
    (fc - pwp)*mrzd
  end # TAW

  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # This should be recalculated and saved whenever soils, crop, or root zone depth are changed
  # AD is Allowable Depletion (aka RAW - Readily Available Water)
  # madFrac is fractional form of Maximum Allowable Depletion
  # taw is Total Available Water
  # Result is in inches of water
  def ad_max_inches(mad_frac, taw)
    mad_frac * taw
  end # Max_AD

  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # This should be recalculated and saved whenever soils, crop, or root zone depth are changed
  # fc is field capacity
  # mrzd is managed root zone depth
  # adMax is calculated in AD_Max_inches
  # Result is in percent
  def pct_moisture_at_ad_min(fc, ad_max, mrzd)
    (fc - (ad_max/mrzd)) * 100
  end  # Pct_Moisture_At_AD_Min
  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # daily_Rain is accumulated rainfall for the day in inches
  # daily_Irrigation is accumulated irigation for the day in inches
  # adj_ET is calculated in module EtCalculator
  # Result is in inches of water
  def change_in_daily_storage(daily_rain, daily_irrig, adj_et)
    # If any of these are nil, use 0.0 for the calculation instead of blowing up
    daily_rain ||= 0.0; daily_irrig ||= 0.0; adj_et ||= 0.0
    (daily_rain + daily_irrig) - adj_et
  end # Change_In_Daily_Storage

  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # AD is Allowable Depletion (aka RAW - Readily Available Water)
  # prev_Daily_AD is previous day's daily AD
  # delta_Stor is calculated in Change_In_Daily_Storage
  # Result is in inches of water, the smaller of max_ad_inches and the sum of previous + delta
  def daily_ad(prev_daily_ad, delta_stor, mad_frac, taw)
    max_ad_inches = ad_max_inches(mad_frac,taw)
    [max_ad_inches,prev_daily_ad + delta_stor].min
  end # Daily_AD
  

  ###############################################
  # Created:: 05Dec12
  # Author:: R Wayne
  # AD is Allowable Depletion (aka RAW - Readily Available Water)
  # prev_Daily_AD is previous day's daily AD
  # delta_Stor is calculated in Change_In_Daily_Storage
  # Results are in inches of water: [AD,DD]
  #  AD is the smaller of max_ad_inches and the sum of previous + delta
  #  Deep Drainage is what's left over above max_ad_inches
  def daily_ad_and_dd(prev_daily_ad, delta_stor, mad_frac, taw)
    max_ad_inches = ad_max_inches(mad_frac,taw)
    water_inches = prev_daily_ad + delta_stor
    # For some reason we're getting a rounding error here, where the water is coming up
    # infinitesmially greater than max_ad_inches. So only look for significant DD.
    if (water_inches - max_ad_inches).abs > 0.001
      [max_ad_inches,water_inches - max_ad_inches]
    else
      [water_inches,0.0]
    end
  end
  
  ###############################################
  # Created:: 15Jun11
  # Author:: P Kaarakka & Rick Wayne
  # mad_frac and taw are used to calculate Max AD in inches
  # mrzd, pct_mad_min and obs_pct_moisture are used to calculate the new AD
  # Result is Allowable Depletion in inches of water (aka RAW - Readily Available Water)
  def daily_ad_from_moisture(mad_frac,taw,mrzd,pct_mad_min,obs_pct_moisture)
    max_ad_inches = ad_max_inches(mad_frac,taw)
    [max_ad_inches,mrzd * ((obs_pct_moisture - pct_mad_min) / 100)].min
  end
  
  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # pwp is permanent wilting point
  # mrzd is managed root zone depth
  # pct_Moisture_At_AD_Min is calculated in Pct_Moisture_At_AD_Min
  # ad is current day's AD
  # pct_Moisture_Obs is observed soil moisture for the day
  # if pct_moisture_obs is supplied, just return that
  # Result is in percent  
  def pct_moisture_from_ad(pwp, fc, ad_max, ad, mrzd, pct_moisture_obs=nil)
    pct_moisture_at_ad_min = pct_moisture_at_ad_min(fc, ad_max, mrzd)
    pct_moisture_obs || ([(pct_moisture_at_ad_min+((ad/mrzd)*100)),pwp].max)
  end # Daily_TWC
  
  ###############################################
  # Created:: 18May11
  # Author:: P Kaarakka
  # ad_Max is calculated in AD_Max_inches
  # prev_Daily_AD is previous day's daily AD
  # delta_Stor is calculated in Change_In_Daily_Storage
  # Result is in inches/day
  def daily_deep_drainage_volume(ad_max, prev_daily_ad, delta_stor)
    temp_ddv = prev_daily_ad + delta_stor
    if temp_ddv > ad_max
      ddv = temp_ddv - ad_max
    else
      ddv = 0
    end
  end # Daily_Deep_Drainage_Volume
end

