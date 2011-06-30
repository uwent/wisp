class WispController < ApplicationController
  before_filter :ensure_signed_in, :except => [:index]
  before_filter :current_user, :get_group, :get_current_ids
  def index
  end

  def pivot_crop
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @pivots = Pivot.where(:farm_id => @farm_id)
    @field = Field.find(@field_id) if @field_id
    @fields = Field.where(:pivot_id => @pivot_id)
    @crop = Crop.find(@crop_id) if @crop_id
    @crops = Crop.where(:field_id => @field_id)
  end

  def crop_setup_grid
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @pivots = Pivot.where(:farm_id => @farm_id)
    @field = Field.find(@field_id) if @field_id
    @fields = Field.where(:pivot_id => @pivot_id)
    @crop = Crop.find(@crop_id) if @crop_id
    @crops = Crop.where(:field_id => @field_id)
    render :layout => false
  end

  def weather
    # FIXME: Should use the selected station, not be fixed!
    @weather_station_id = 1
  end

  def lookup
  end

  def field_status
    puts "field_status"
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @field = Field.find(@field_id) if @field_id
    logger.info @farm_id
    logger.info @field_id
    logger.info @pivot_id
    @ad_data = ad_data(@field_id,'2011-05-01','2011-06-01')
    @projected_ad_data = projected_ad(@ad_data,@field_id)
  end

  def farm_status
  end

  def report_setup
  end
    
  private
  def ad_data(field_id,start_date,end_date)
    recs = FieldDailyWeather.where(
      "field_id=? and date >= ? and date <= ?",field_id,start_date,end_date
      ).sort {|fdw,fdw2| fdw[:date] <=> fdw2[:date]}
    # recs.collect { |rec| rec[:ad] ? rec[:ad] : 0.0 }
    # For now, throw in random numbers. We'll want to return the last 7 elements,
    # and project two
    recs.collect { |e| rand }
  end
  
  def projected_ad(ad_data,field_id)
    projected_ad_data = []
    0..ad_data.size.times {projected_ad_data << 0.0}
    projected_ad_data[-1] = ad_data[-1]
    increment = ad_data[-1] - ad_data[-2]
    projected_ad_data << ad_data[-1] + increment
    projected_ad_data << projected_ad_data[-1] + increment
  end
end
