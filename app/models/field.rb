# -*- coding: utf-8 -*-
# TODO: Use HTTParty
# require 'net/http'
# require 'uri'

class Field < ApplicationRecord
  after_create :create_dependent_objects
  after_save :set_fdw_initial_moisture, :do_balances
  before_validation :set_defaults, on: :create

  include HTTParty

  BASE_ENDPOINT = ENV['AG_WEATHER_BASE_URL']

  ET_ENDPOINT = "#{BASE_ENDPOINT}/evapotranspirations"
  DD_ENDPOINT = "#{BASE_ENDPOINT}/degree_days"

  START_DATE = [4, 1]
  END_DATE = [11, 30]
  EMERGENCE_DATE = [5, 1]

  DEFAULT_INITIAL_AD = -999.0
  DEFAULT_FIELD_CAPACITY = 0.31
  DEFAULT_PERM_WILTING_PT = 0.14

  EPSILON = 0.0000001

  PCT_COVER_METHOD = 1
  LAI_METHOD = 2

  include ADCalculator
  include ETCalculator

  belongs_to :pivot, optional: true
  belongs_to :soil_type, optional: true

  has_many :crops, dependent: :destroy
  has_many :field_daily_weather, -> { order(:date) }, dependent: :destroy
  has_many :multi_edit_links, dependent: :destroy
  has_many :weather_stations, through: :multi_edit_links

  delegate :farm, to: :pivot, prefix: true, allow_nil: true

  validates :target_ad_pct,
    numericality: {
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 100.0
    },
    allow_nil: true

  validates :et_method,
    inclusion: {
      in: [PCT_COVER_METHOD, LAI_METHOD]
    }

  def self.starts_on(year)
    Date.civil(year, *START_DATE)
  end

  def self.ends_on(year)
    Date.civil(year, *END_DATE)
  end

  def self.emerges_on(year)
    Date.civil(year, *EMERGENCE_DATE)
  end

  def et_method_name
    {
      PCT_COVER_METHOD => 'Pct Cover',
      LAI_METHOD => 'LAI'
    }[et_method]
  end

  def adj_et(fdw)
    return unless current_crop && current_crop.plant && fdw.ref_et

    if et_method == PCT_COVER_METHOD
      return unless fdw.pct_cover

      current_crop.plant.calc_adj_et_pct_cover(fdw.ref_et, fdw.pct_cover)
    elsif et_method == LAI_METHOD
      return unless fdw.leaf_area_index

      current_crop.plant.calc_adj_et_lai(fdw.ref_et, fdw.leaf_area_index)
    end
  end

  #FIXME: this is just a placeholder hack for now, returning the one w/the
  # latest emergence date

  # pseduocode for the "real" algorithm
  # given a date:
  # look for the latest crop in the current year whose emergence date is past
  def current_crop
    @current_crop ||= crops.reload.order(:emergence_date).last
  end

  def year
    return Time.now.year unless pivot_farm

    pivot_farm.year
  end

  def field_capacity
    if (val = read_attribute(:field_capacity)) && val != 0.0
      val
    elsif soil_type
      soil_type.field_capacity
    else
      DEFAULT_FIELD_CAPACITY
    end
  end

  def field_capacity_pct=(val)
    val = val.to_f / 100.0
    write_attribute(:field_capacity, val)
  end

  def field_capacity=(val)
    write_attribute(:field_capacity, val.to_f)
  end

  def field_capacity_pct
    field_capacity * 100.0
  end

  def perm_wilting_pt
    if (val = read_attribute(:perm_wilting_pt)) && val != 0.0
      val
    elsif soil_type
      soil_type.perm_wilting_pt
    else
      DEFAULT_PERM_WILTING_PT
    end
  end

  def perm_wilting_pt_pct=(val)
    write_attribute(:perm_wilting_pt,val.to_f / 100.0)
  end

  def perm_wilting_pt=(val)
    write_attribute(:perm_wilting_pt,val.to_f)
  end

  def perm_wilting_pt_pct
    perm_wilting_pt * 100.0
  end

  def create_dependent_objects
    create_crop
    create_field_daily_weather
    save!
  end

  def create_crop
    crops.create!(
      emergence_date: default_emergence_date,
      max_allowable_depletion_frac: 0.5,
      initial_soil_moisture: 100 * field_capacity)
  end

  def create_field_daily_weather
    start_date, end_date = date_endpoints
    pct_cover = nil
    lai = nil
    (start_date..end_date).each do |date|
      # Could use update_canopy for this, but why go 'round twice? Still, there's a smell.
      days_since_emergence = date - emergence_date
      if et_method == LAI_METHOD
        # FIXME: This call to lai_corn s/b delegated to current_crop.plant
        lai = days_since_emergence >= 0 ? lai_corn(days_since_emergence) : 0.0
        pct_cover = nil
      elsif et_method == PCT_COVER_METHOD
        pct_cover = 0.0
        lai = nil
      end
      field_daily_weather.create!(
        date: date,
        ref_et: 0.0,
        ad: 0.0,
        adj_et: 0.0,
        leaf_area_index: lai,
        calculated_pct_cover: pct_cover)
    end
    set_fdw_initial_moisture
  end

  def emergence_date
    @emergence_date ||= current_crop.try(:emergence_date) || default_emergence_date
  end

  def cropping_year
    @cropping_year ||= pivot.try(:cropping_year) || Time.now.year
  end

  def date_endpoints
    [
      Date.civil(cropping_year, *START_DATE),
      Date.civil(cropping_year, *END_DATE)
    ]
  end

  def can_calculate_initial_ad?
    current_crop &&
      current_crop.max_root_zone_depth &&
      field_capacity &&
      perm_wilting_pt &&
      current_crop.max_allowable_depletion_frac &&
      current_crop.initial_soil_moisture
  end

  def new_year
    crops.each { |c|  c.new_year }
    field_daily_weather.each do |daily_weather|
      daily_weather.destroy! if daily_weather.date.year < Time.now.year
    end
    self.reload
    create_field_daily_weather
    set_fdw_initial_moisture
    do_balances
  end

  def initial_ad
    return DEFAULT_INITIAL_AD unless can_calculate_initial_ad?

    mrzd = current_crop.max_root_zone_depth
    taw = taw(field_capacity, perm_wilting_pt, mrzd)
    mad_frac = current_crop.max_allowable_depletion_frac

    pct_mad_min = pct_moisture_at_ad_min(field_capacity, ad_max_inches(mad_frac, taw), mrzd)

    obs_pct_moisture = current_crop.initial_soil_moisture
    daily_ad_from_moisture(mad_frac, taw, mrzd, pct_mad_min, obs_pct_moisture)
  end

  def update_with_emergence_date(emergence_date)
    transaction do
      update_canopy(emergence_date)
      set_fdw_initial_moisture
      do_balances
    end
  end

  def update_canopy(emergence_date)
    if et_method == LAI_METHOD
      # FIXME: Would probably speed up creating new fields and crops A LOT if we did defer_balances here!
      days_since_emergence = 0
      field_daily_weather.each do |fdw|
        next unless fdw.date >= emergence_date
        fdw.leaf_area_index = current_crop.plant.lai_for(days_since_emergence,fdw)
        fdw.save!
        days_since_emergence += 1
      end
      save!
    elsif et_method == PCT_COVER_METHOD
      # There is no automatic canopy calculation for % cover, at least not now. So just set everything that's nil to 0.0.
      FieldDailyWeather.defer_balances
      field_daily_weather.each do |fdw|
        unless fdw.pct_cover # don't bother if already set; checks both calculated and entered
          fdw.calculated_pct_cover = 0.0
          fdw.save!
        end
      end
      FieldDailyWeather.undefer_balances
      # Now that we've gone through and saved everything, we can trigger once through for AD balances
      field_daily_weather.first.save! if field_daily_weather.first
    else
      raise "Unknown ET Method for this field: #{et_method}"
    end
  end

  def get_et
    unless pivot.latitude && pivot.longitude
      logger.warn("Field :: get_et: no lat/long for pivot")
    end
    logger.info("Field :: Starting get_et")
    start_date = field_daily_weather[0].date.to_s
    end_date = field_daily_weather[-1].date.to_s

    vals = {}
    begin
      query = {
        lat: pivot.latitude.round(1),
        long: pivot.longitude.round(1),
        start_date: start_date,
        end_dat: end_date
      }
      response = HTTParty.get(ET_ENDPOINT, query: query, timeout: 10)
      json = JSON.parse(response.body, symbolize_names: true)
      puts json
      vals = {}
      json[:data].each do |day|
        vals[day[:date]] = day[:value]
      end
    rescue Exception => e
      logger.warn("Field :: Could not get ETs from the net; connected? (#{e})")
    end
    field_daily_weather.each do |fdw|
      if fdw.ref_et == nil || fdw.ref_et == 0.0
        if vals[fdw.date.to_s]
          fdw.ref_et = vals[fdw.date.to_s]
          fdw.save!
        end
      end
    end
    logger.info("Field :: Done with get_et")
  end

  def need_degree_days?
    current_crop.plant.uses_degree_days?(et_method)
  end

  def get_degree_days(method = 'Simple', base_temp = 50.0, upper_temp = nil)
    return unless pivot.latitude && pivot.longitude

    start_date = field_daily_weather[0].date.to_s
    end_date = field_daily_weather[-1].date.to_s

    # TODO: Extract method.
    logger.info("Field :: Starting get_dds for #{start_date} to #{end_date} at #{pivot.latitude},#{pivot.longitude}")

    begin
      query = {
        lat: pivot.latitude.round(1),
        long: pivot.longitude.round(1),
        start_date: start_date,
        end_dat: end_date,
        base: base_temp,
        upper: upper_temp ? upper_temp : 150
      }
      response = HTTParty.get(DD_ENDPOINT, query: query, timeout: 10)
      json = JSON.parse(response.body, symbolize_names: true)
      puts json
      vals = {}
      json[:data].each do |day|
        vals[day[:date]] = day[:value]
      end
    rescue Exception => e
      logger.warn("Field :: Could not get DDs from the agweather; connected? (#{e})")
    end
    field_daily_weather.each do |fdw|
      if fdw.degree_days == nil || fdw.degree_days == 0.0
        if vals[fdw.date.to_s]
          fdw.degree_days = vals[fdw.date.to_s]
          # TODO: Determine if this is really the appropriate place to trigger this
          fdw.adj_et = adj_et(fdw)
          fdw.save!
        end
      end
    end
    logger.info("Field :: Done with get_dds")
  end

  def fdw_index(date)
    # why the *^$@ can't I just subtract the database field instead of this rigamarole?
    return nil unless field_daily_weather.first
    fdw_date = Date.parse(field_daily_weather.first.date.to_s)
    (date - fdw_date).to_i
  end

  # hook method for FDW objects to alert us of their (newly changed?) AD
  def update_fdw(field_daily_wx)
    # puts "field#update_fdw: wx calling us has #{field_daily_wx.field.inspect}"
    # day = fdw_index(field_daily_wx.date)
    # unless day
    #   puts "Could not calculate the index for the field_daily_wx"
    #   return
    # end
    # puts "updating field daily wx for day #{day}"
    # field_daily_wx.update_balances(day == 0 ? nil : field_daily_weather[day-1])
  end

  # return the Max AD (in inches)
  def ad_max
    taw = taw(field_capacity, perm_wilting_pt, current_crop.max_root_zone_depth)
    mad_frac = current_crop.max_allowable_depletion_frac
    ad_max_inches(mad_frac,taw)
  end

  def ad_at_pwp
    taw = taw(field_capacity, perm_wilting_pt, current_crop.max_root_zone_depth)
    # Call method from ADCalculator
    ad_inches_at_pwp(taw,current_crop.max_allowable_depletion_frac)
  end

  def pct_cover_changed_by_date(date)
    pct_cover_changed(field_daily_weather[fdw_index(date)])
  end

  def pct_cover_changed(fdw)
    # could re-interpolate everything, but let's just do the ones around the new point
    midpoint_pct_cover = fdw.pct_cover
    fdw_index = field_daily_weather.index {|an_fdw| an_fdw[:date] == fdw[:date]}
    first_fdw_index,last_fdw_index = surrounding(field_daily_weather,fdw_index,:entered_pct_cover)
    if field_daily_weather[first_fdw_index].date < current_crop.emergence_date
      first_fdw_index = field_daily_weather.index { |fdw| fdw.date == current_crop.emergence_date }
    end
    linear_interpolation(field_daily_weather,first_fdw_index,fdw_index,:entered_pct_cover,:calculated_pct_cover)
    if field_daily_weather[last_fdw_index][:entered_pct_cover]
      linear_interpolation(field_daily_weather,fdw_index,last_fdw_index,:entered_pct_cover,:calculated_pct_cover)
    else
      # go one week from last-entered value
      field_daily_weather[fdw_index+1..fdw_index+6].each do |extrapolated_fdw|
        extrapolated_fdw[:calculated_pct_cover] = midpoint_pct_cover
      end
    end
  end

  def weather_for(date, end_date = nil)
    if end_date
      field_daily_weather.select { |fdw| fdw.date >= date && fdw.date <= end_date }
    else
      field_daily_weather.select { |fdw| fdw.date == date }
    end
  end

  # For a given date range, determine if we have an AD below zero, whether in the range
  # or in the projected data. We assume that the projected data follow the range.
  # Return {self => {date => ad}} or nil if no problems.
  def problem(date = nil, end_date = nil)
    date ||= Date.today
    existing_wx = weather_for(date)
    projected_wx = weather_for(date+1,date+2)
    ad_problem_threshold = 0.0

    existing_problem = nil
    # Is start date AD below zero?
    if existing_wx && (existing_wx.size > 0) &&  existing_wx.last.ad < ad_problem_threshold
      existing_problem = [existing_wx.last.date,existing_wx.last.ad]
    else
      #Start date AD is above zero so check projected two days ahead for problem.
      projected_problem = nil
      if projected_wx
        projected_wx.each do |prj_wx|
          if prj_wx && prj_wx.ad && prj_wx.ad < ad_problem_threshold
            projected_problem = [prj_wx.date,prj_wx.ad]
            break
          end
        end
      end
    end

    if existing_problem
      #{self => [existing_problems.first.date,existing_problems.first.ad]}
      {self => existing_problem}
    elsif projected_problem
      {self => projected_problem}
    else
      nil
    end
  end

  def within_epsilon(val, other_val)
    (val - other_val).abs < EPSILON
  end

  # If the incoming attributes have an entry for attrib symbol, and it's the same value (within EPSILON)
  # as the default value for our soil, delete the entry from the attributes.
  def remove_incoming_if_default(my_soil, incoming_attribs, attrib_symbol)
    if incoming_attribs[attrib_symbol] && within_epsilon(incoming_attribs[attrib_symbol].to_f,my_soil[attrib_symbol])
      incoming_attribs.delete(attrib_symbol)
    end
    incoming_attribs
  end

  def groom_for_defaults(incoming_attribs)
    incoming_attribs.delete(:et_method) if incoming_attribs[:et_method] == nil
    my_soil = soil_type
    if incoming_attribs[:soil_type_id].to_i == soil_type_id
      # why set it if it hasn't changed? Just biff it
      incoming_attribs.delete(:soil_type_id)
    else
      # If the user has changed the soil type, they're overwriting any explicit values they'd previously entered,
      # whether implicitly via the soil type defaults, or explicity via newly-entered values.
      # Note that we could also probably do with with soil_type_id=(), but this is already here.
      self[:field_capacity] = nil
      self[:perm_wilting_pt] = nil
      # Get rid of FC and PWP if they correspond to the old soil's default values.
      # The two remove_incoming lines that get called after this will get rid of ones == to NEW default values.
      remove_incoming_if_default(my_soil,incoming_attribs,:field_capacity)
      remove_incoming_if_default(my_soil,incoming_attribs,:perm_wilting_pt)
      my_soil = SoilType.find(incoming_attribs[:soil_type_id].to_i)
    end
    remove_incoming_if_default(my_soil,incoming_attribs,:field_capacity)
    remove_incoming_if_default(my_soil,incoming_attribs,:perm_wilting_pt)
  end

  def target_ad_in
    logger.warn("Field :: tadi: tadp nil"); return nil unless (tadp = self[:target_ad_pct])
    logger.warn("Field :: tadi: cc nil"); return nil unless (cc = current_crop)
    logger.warn("Field :: tadi: cmf nil"); return nil unless (crop_mad_frac = cc.max_allowable_depletion_frac)
    logger.warn("Field :: tadi: mrzd nil"); return nil unless (mrzd = cc.max_root_zone_depth)
    logger.warn("Field :: tadi: fc or pwp nil"); return nil unless (fc = field_capacity) && (pwp = perm_wilting_pt)
    mad_inches = ad_max_inches(crop_mad_frac,taw(fc,pwp,mrzd))
    (tadp / 100.0) * mad_inches
  end

  ###### VALIDATORS & LIFECYCLE #########

  def set_fdw_initial_moisture
    fc = self[:field_capacity] || field_capacity
    first_fdw = field_daily_weather[0]
    unless (first_fdw && fc)
      logger.warn "Field :: set_fdw_initial_moisture called but fc or first fdw was missing"
      return
    end
    first_fdw.calculated_pct_moisture = 100*fc
    pwp = self[:perm_wilting_pt] || perm_wilting_pt
    unless pwp
      logger.warn "Field :: set_fdw_initial_moisture: pwp for field was nil, using default soil type"
      pwp = SoilType.default_soil_type.perm_wilting_pt
    end
    first_fdw.set_ad_from_calculated_moisture(fc,pwp,current_crop.max_root_zone_depth)
    first_fdw.save!
    # puts "set_fdw_initial: set the AD for the first FDW, it's now:"
    # puts first_fdw.inspect
    # do_balances(first_fdw.date + 1)
  end

  def max_adj_et_in_past_week(fdw_index)
    max_index = fdw_index
    max_index = field_daily_weather.size -1 if max_index >= field_daily_weather.size
    fdw_index -= 6
    fdw_index = 0 if fdw_index < 0
    field_daily_weather[fdw_index,max_index].inject(0.0) { |max, fdw| [max,fdw.adj_et].max }
  end

  def do_balances(date = nil)
    # logger.info "do_balances called with date #{date}"
    day = date ? fdw_index(date) : 0
    return unless field_daily_weather && field_daily_weather[0]
    # Get yesterday's index to initialize prev_ad, but don't go below 0!
    prev_ad = field_daily_weather[[0,day - 1].max].ad
    # puts "do_balances going from #{day} onward (date was #{date}), prev_ad #{prev_ad} and starting FDW is"
    # puts field_daily_weather[day].inspect
    # Track previous adjusted ADs as we go, and use the max value from the past week to replace if necessary
    rb = RingBuffer.new(7)
    field_daily_weather[day..-1].each do |fdw|
      # Remember the max adjusted ET within the last week. If there wasn't a nonzero one, use the last available one.
      #last_adj_et = rb.max || rb.last_nonzero
      # ARB: changed 8/23/19 to take average of top 3 in last 7 days
      last_adj_et = rb.mean_top_3

      # logger.info "do_balances on #{fdw.date}: prev_ad is #{prev_ad} and last_adj_et is #{last_adj_et}"
      fdw.old_update_balances(prev_ad,last_adj_et)
      # puts "after update_balances, ad now #{fdw.ad}" if day < 5
      prev_ad = fdw.ad
      rb.add(fdw.adj_et) # Add this one's adj_et value to the running list
      fdw.save!
    end
  end

  def act # placeholder for dummy JSON info, to be replaced by "action" button in grid
    ""
  end

  private

  def default_emergence_date
    Date.civil(cropping_year, *EMERGENCE_DATE)
  end

  def set_defaults
    self.name ||= "New field (Pivot ID: #{pivot_id})"
    self.soil_type = SoilType.default_soil_type
    self.et_method ||= PCT_COVER_METHOD
  end
end
