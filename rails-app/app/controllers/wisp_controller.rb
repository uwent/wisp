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
  def field_status_data
    # puts "field_status"
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    # puts "FIELD_STATUS*****: #{@pivot.name}" if @pivot
    @field = Field.find(@field_id) if @field_id
    @field_weather_data = @field.field_daily_weather
    logger.info @farm_id
    logger.info @field_id
    logger.info @pivot_id 
    start_date = Date.today - 7
    end_date = Date.today - 1
    @ad_recs = FieldDailyWeather.fdw_for(@field_id,start_date,end_date)
    @ad_data = @ad_recs.collect { |fdw| fdw.ad }
    @projected_ad_data = FieldDailyWeather.projected_ad(@ad_recs)
    @dates,@date_str = make_dates(start_date,end_date)
    @summary_data = FieldDailyWeather.summary(@field.id)
  end

  def field_status
    field_status_data
    # now that we've got the last week's fdw recs, check if any need ET
    @ad_recs.each do |adr|
      if adr.ref_et == nil || adr.ref_et == 0.0
        @field.get_et
        break
      end
    end
    if params[:ajax]
      render :layout => false
    end
  end
  
  def projection_data
    field_status_data
    respond_to do |format|
      format.json { render :json => {:ad_data => @ad_data,:projected_ad_data => @projected_ad_data}} 
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

  
  # Usually start_date will be a week ago and finish_date will be yesterday
  def make_dates(start_date,finish_date)
    day = 0
    dates = []
    date_str = ''
    (start_date..(finish_date + 2)).each do |date|
      dates << date
      if date == finish_date + 1
        date_str += "#{day}: 'Today',"
      else
        date_str += "#{day}: '#{date.strftime('%b %d')}',"
      end
      day += 1
    end
    [dates,date_str]
  end
  
end
