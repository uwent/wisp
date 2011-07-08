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
    # puts "field_status"
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    puts "FIELD_STATUS*****: #{@pivot.name}"
    @field = Field.find(@field_id) if @field_id
    logger.info @farm_id
    logger.info @field_id
    logger.info @pivot_id
    @ad_data = ad_data(@field_id,'2011-07-05','2011-07-13')
    # @projected_ad_data = projected_ad(@ad_data,@field_id)
    @projected_ad_data = [-0.25,-0.25]
    @ad_data[-1] = -0.3
    @ad_data[-2] = -0.15
    start_date = Date.parse('2011-07-05')
    end_date = Date.parse('2011-07-13')
    @dates = {}
    day = 0
    (start_date..end_date).each { |date| @dates[day] = date.strftime('%b %d'); day += 1 }
    puts @dates.inspect
  end

  def farm_status
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
end
