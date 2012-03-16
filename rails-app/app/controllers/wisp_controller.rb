class WispController < ApplicationController
  before_filter :ensure_signed_in, :only => [:farm_status, :pivot_crop, :field_status]
  before_filter :current_user
  before_filter :get_current_ids, :except => [:home,:index]
  before_filter :get_farm_id, :except => [:index]
  
  def index
  end

  def home
    index
    render :template => 'wisp/index'
  end
  
  def get_farm_id
    @farm_id,@farm = get_and_set(Farm,Group,@group_id)
    raise "No farm!" unless @farm
  end
  
  def pivot_crop
    # these variables are the initial values when the page is loaded. After the user
    # starts clicking, all bets are off!
    @pivot,@pivot_id = [@farm.pivots.first,@farm.pivots.first[:id]]
    @field,@field_id = [@pivot.fields.first,@pivot.fields.first[:id]]
    # @crop_id = @field.current_crop[:id]
    # # @farm = Farm.find(@farm_id) if @farm_id
    # @pivot = Pivot.find(@pivot_id) if @pivot_id
    # @pivots = Pivot.where(:farm_id => @farm_id)
    # @field = Field.find(@field_id) if @field_id
    # @fields = Field.where(:pivot_id => @pivot_id)
    # @crop = Crop.find(@crop_id) if @crop_id
    # @crops = Crop.where(:field_id => @field_id)
    # FIXME: Need to filter everything below pivot for current year
    if params[:ajax]
      render :layout => false
    end
  end

  def field_setup_grid
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot_id,@pivot = get_and_set(Pivot,Farm,@farm_id)
    @pivots = Pivot.where(:farm_id => @farm_id)
    # @field = @pivot.fields.first
    # @field_id = @field[:id]
    # @fields = Field.where(:pivot_id => @pivot_id)
    # @crop = Crop.find(@crop_id) if @crop_id
    # @crops = Crop.where(:field_id => @field_id)
    render :layout => false
  end

  def crop_setup_grid
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @pivots = Pivot.where(:farm_id => @farm_id)
    @field,@field_id = get_and_set(Field,Pivot,@pivot_id)
    @field = Field.find(@field_id) if @field_id
    @fields = Field.where(:pivot_id => @pivot_id)
    @crop = @field.current_crop
    @crop_id = @crop[:id]
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
  
  # Given a season-start date of initial_date and (possibly) a point in that
  # season in cur_date, find the start and end of the week encompassing cur_date.
  # If cur_date is nil, use today_or_latest and work from there.
  def date_strs(initial_date,cur_date=nil)
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
    # So now end_date is provisionally set; find start_date and coerce end_date to
    # week boundaries
    weeks = ((end_date - initial_date).to_i / 7).to_i
    start_date = initial_date + (7 * weeks)
    end_date = start_date + 6
    cur_date = end_date.strftime("%Y-%m-%d")
    return [start_date,end_date,cur_date]
  end
  
  def field_status_data(cur_date=nil)
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @field = Field.find(@field_id) if @field_id
    @field_weather_data = @field.field_daily_weather
    @initial_date = @field_weather_data.first.date
    start_date,end_date,@cur_date = date_strs(@initial_date,cur_date)
    @ad_recs = FieldDailyWeather.fdw_for(@field_id,start_date,end_date)
    @ad_data = @ad_recs.collect { |fdw| fdw.ad }
    @projected_ad_data = FieldDailyWeather.projected_ad(@ad_recs)
    @dates,@date_str,@date_hash = make_dates(start_date,end_date)
    puts "field_status_data: cur_date #{@cur_date}, dates #{@dates.inspect}"
    @summary_data = FieldDailyWeather.summary(@field.id)
    @target_ad_data = target_ad_data(@field,@ad_data)
  end

  def field_status
    logger.info "field_status: group #{@group_id} user #{@user_id} farm #{@farm_id} pivot #{@pivot_id} field #{@field_id}"
    @pivot_id,@pivot = get_and_set(Pivot,Farm,@farm_id)
    @field_id,@field = get_and_set(Field,Pivot,@pivot_id)
    @cur_date = params[:cur_date]
    session[:today] = @cur_date
    field_status_data(@cur_date) # @cur_date may be nil, but will be set if so
    # now that we've got the last week's fdw recs, check if any need ET
    @ad_recs.each do |adr|
      if adr.ref_et == nil || adr.ref_et == 0.0
        @field.get_et
        break
      end
    end
    if params[:ajax]
      render :template => 'wisp/field_status', :layout => false
    end
  end
  
  def field_status_from_javascript
    "******* I AM A CAN OF TUNA **********"
    field_status
  end
  
  def projection_data
    @field_id = params[:field_id]
    @field = Field.find(@field_id)
    @farm = @field.pivot.farm; @farm_id = @farm[:id]
    field_status_data(params[:cur_date]) # may be nil
    respond_to do |format|
      format.json { render :json => {:ad_data => @ad_data,:projected_ad_data => @projected_ad_data,
        :target_ad_data => @target_ad_data, :labels => @date_hash}} 
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
    get_current_ids
    if @farm && !@group_id
      @group_id = @farm.group[:id]
    end
    if params[:ajax]
      render :layout => false
    end
  end

  # Ajax-accessible summary/projected box
  def summary_box
    get_current_ids
    @field_id = params[:field_id]
    field_status_data(params[:cur_date])
    render :partial => 'wisp/partials/summary_box'
  end
  
  def report_setup
  end
  
  def set_farm
    logger.info "SET_FARM: setting the ids to #{params[:farm_id]}"
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
    logger.info "set field with id #{params[:id]}"
    if params[:field_id]
      @field_id =  params[:field_id]
      @field = Field.find(@field_id)
      session[:field_id] = @field_id
    end
    render :json => {:field_id => params[:field_id]}
  end
  
  private

  
  # Usually start_date will be a week ago and finish_date will be yesterday
  def make_dates(start_date,finish_date)
    day = 0
    dates = []
    date_hash = {}
    date_str = ''
    (start_date..(finish_date + 2)).each do |date|
      dates << date
      if date == Date.today
        date_str += "#{day}: 'Today',"
        date_hash[day] = 'Today';
      else
        date_str += "#{day}: '#{date.strftime('%b %d')}',"
        date_hash[day] = date.strftime('%b %d')
      end
      day += 1
    end
    [dates,date_str,date_hash]
  end
  
end
