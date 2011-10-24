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
  def field_status_data(cur_date=nil)
    # puts "field_status"
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    # puts "FIELD_STATUS*****: #{@pivot.name}" if @pivot
    @field = Field.find(@field_id) if @field_id
    @field_weather_data = @field.field_daily_weather
    start_date=nil
    if (cur_date)
      begin
        end_date = Date.parse(cur_date) - 1
      rescue Exception => e
        logger.warn "Date reset problem: #{e.to_s}"
        end_date = today_or_latest(@field_id) - 1
      end
    else
      end_date = today_or_latest(@field_id) - 1
    end
    start_date = end_date - 6
    logger.info "wisp#field_status_data: start_date #{start_date}, end_date #{end_date}"
    @ad_recs = FieldDailyWeather.fdw_for(@field_id,start_date,end_date)
    @ad_data = @ad_recs.collect { |fdw| fdw.ad }
    @projected_ad_data = FieldDailyWeather.projected_ad(@ad_recs)
    @dates,@date_str = make_dates(start_date,end_date)
    @summary_data = FieldDailyWeather.summary(@field.id)
    @target_ad_data = target_ad_data(@field,@ad_data)
    logger.info "dates #{@dates.inspect}, date_str #{@date_str.inspect}, ad_data #{@ad_data.inspect}, target #{@target_ad_data.inspect}"
  end

  def field_status
    logger.info "field_status"
    @cur_date = params[:cur_date]
    session[:today] = @cur_date
    field_status_data(@cur_date) # may be nil
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
    field_status_data(params[:cur_date]) # may be nil
    respond_to do |format|
      format.json { render :json => {:ad_data => @ad_data,:projected_ad_data => @projected_ad_data,
        :target_ad_data => @target_ad_data}} 
    end
  end

  # Make a line for the Target AD value for this field
  # We just use the length of projected_ad_data
  def target_ad_data(field,ad_data)
    return nil unless field.target_ad_pct
    ret = []
    (ad_data.length + 2).times { ret << (field.target_ad_pct / 100.0) * field.ad_max }
    ret
  end
  
  def farm_status
    if params[:ajax]
      render :layout => false
    end
  end

  # Ajax-accessible summary/projected box
  def summary_box
    field_status_data
    render :partial => 'wisp/partials/summary_box'
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
      if date == Date.today
        date_str += "#{day}: 'Today',"
      else
        date_str += "#{day}: '#{date.strftime('%b %d')}',"
      end
      day += 1
    end
    [dates,date_str]
  end
  
end
