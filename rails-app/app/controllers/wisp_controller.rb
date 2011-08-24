class WispController < ApplicationController
  before_filter :ensure_signed_in, :except => [:index]
  before_filter :current_user, :get_current_ids, :except => [:index, :set_farm, :set_pivot, :set_field, :set_crop]
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
    # FIXME: Need to filter everything below pivot for current year
    if params[:ajax]
      render :layout => false
    end
  end

  def field_setup_grid
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @pivots = Pivot.where(:farm_id => @farm_id)
    @field = Field.find(@field_id) if @field_id
    @fields = Field.where(:pivot_id => @pivot_id)
    @crop = Crop.find(@crop_id) if @crop_id
    @crops = Crop.where(:field_id => @field_id)
    render :layout => false
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
    if params[:ajax]
      render :layout => false
    end
  end

  def lookup
  end

  def field_status
    # puts "field_status"
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    puts "FIELD_STATUS*****: #{@pivot.name}" if @pivot
    @field = Field.find(@field_id) if @field_id
    logger.info @farm_id
    logger.info @field_id
    logger.info @pivot_id 
    start_date = Date.today - 6
    end_date = Date.today
    @ad_data = ad_data(@field_id,start_date,end_date)
    @projected_ad_data = projected_ad(@ad_data,@field_id)
    @dates,@date_str = make_dates(start_date,end_date)
    # puts @dates.inspect
    if params[:ajax]
      render :layout => false
    end
  end

  def farm_status
    if params[:ajax]
      render :layout => false
    end
  end

  def report_setup
  end
  
  def set_farm
    puts "SET_FARM: setting the ids to #{params[:farm_id]}"
    session[:farm_id] = @farm_id = params[:farm_id]
    if @farm_id
      @farm = Farm.find(@farm_id)
    end
    render :nothing => true
  end
  
  def set_pivot
    render :nothing => true
  end
  
  def set_field
    render :nothing => true
  end
  
  private
  def ad_data(field_id,start_date,end_date)
    recs = FieldDailyWeather.where(
      "field_id=? and date >= ? and date <= ?",field_id,start_date,end_date
      ).sort {|fdw,fdw2| fdw[:date] <=> fdw2[:date]}
    recs.collect { |e| e.ad }
  end
  
  def projected_ad(ad_data,field_id)
    projected_ad_data = []
    return unless ad_data.size > 0
    # 0..ad_data.size.times {projected_ad_data << 0.0}
    puts "projected_ad: #{ad_data.size} AD records"
    last_day = ad_data[-1] || 0.0
    increment = last_day / 3.0
    projected_ad_data << last_day - increment
    projected_ad_data << projected_ad_data[-1] - increment
  end
  
  def make_dates(start_date,today_date)
    day = 0
    dates = []
    date_str = ''
    (start_date..(today_date - 1)).each do |date|
      dates << date
      date_str += "#{day}: '#{date.strftime('%b %d')}',"
      day += 1
    end
    dates << Date.today
    date_str += "#{day}: 'Today',"
    day += 1
    dates << Date.today + 1
    date_str += "#{day}: '#{(Date.today + 1).strftime('%b %d')}',"
    day += 1
    dates << Date.today + 1
    date_str += "#{day}: '#{(Date.today + 2).strftime('%b %d')}',"
    [dates,date_str]
  end
  
end
