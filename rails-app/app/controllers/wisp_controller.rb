class WispController < ApplicationController
  USER_GUIDE = "USERS_GUIDE_6_29_12.pdf"
  before_filter :ensure_signed_in, :except => [:home,:index, :userguide]
  before_filter :current_user
  before_filter :get_current_ids, :except => [:home,:index, :userguide]
  before_filter :get_farm_id, :except => [:index, :userguide]
  
  def index
  end

  def home
    index
    render :template => 'wisp/index'
  end
   
  def userguide
    send_file "public/#{USER_GUIDE}"
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
      render :partial => '/wisp/partials/pivot_setup_grid'
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
    ensure_group
    @weather_stations = @group.weather_stations
    if @weather_stations == [] || @weather_stations == nil
      flash[:notice] = 'You must first create at least one weather station.'
      redirect_to :controller => 'weather_stations', :action => :new
      return
    end
    if params[:weather_station_id]
      wx_stn_id = params[:weather_station_id].to_i
      @weather_station = @weather_stations.detect { |wxs| wxs[:id].to_i == wx_stn_id}
      unless @weather_station
        logger.info "Could not find station #{wx_stn_id} in #{@weather_stations.collect { |e| e[:id] }.inspect}, using first wx stn in group"
        @weather_station = @weather_stations.first
      end
      # logger.info "Found a station, using #{@weather_station[:id]}"
    else
      logger.info "no wx stn passed, using first wx stn in group"
      @weather_station = @weather_stations.first
    end
    @years = []
    (FieldDailyWeather.first.date.year..Time.now.year).each { |yr| @years << yr }
    @year = params[:year] ? params[:year].to_i : Time.now.year
    # Check that this year's data are present for this station
    @weather_station.ensure_data_for(@year)
    
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
    @field = Field.find(@field_id) if @field_id
    @pivot = Pivot.find(@pivot_id = @field[:pivot_id])
    @farm = Farm.find(@farm_id = @pivot[:farm_id])
    
    @field_weather_data = @field.field_daily_weather
    @initial_date = @field_weather_data.first.date
    start_date,end_date,@cur_date = date_strs(@initial_date,cur_date)
    # logger.info "field_status_data: #{start_date} to #{end_date} at #{@cur_date} for #{@field_id}"
    @ad_recs = FieldDailyWeather.fdw_for(@field_id,start_date,end_date)
    @ad_data = @ad_recs.collect { |fdw| fdw.ad }
    # sets @graph_data, @projected_ad_data,@dates,@date_str,and @date_hash
    graph_data(@field_weather_data,start_date,end_date)
    # logger.info "field_status_data: cur_date #{@cur_date}, start_date #{start_date.to_s}, end_date #{end_date.to_s}, dates #{@dates.inspect}"
    # logger.info "field_status_data: fdw is #{@ad_recs.collect { |e| [e.date,e.field_id,e.ref_et].join(",") }.join("\n")}"
    # logger.info "field_status_data: @graph_data is #{@graph_data.inspect}, @projected is #{@projected_ad_data.inspect}, over #{@date_hash.inspect}"
    @summary_data = FieldDailyWeather.summary(@field.id)
    @target_ad_data = target_ad_data(@field,@ad_data)
  end 

  # from a set of fdw recs and some idea of where to begin looking, return
  # the graph and summary data. This will be a an array of AD numbers, 
  def graph_data(fdw,start_date,end_date)
    ad_recs = @ad_recs # for now
    # reposition the window, if necessary, so that it ends NLT the end of AD data
    # logger.info "graph_data: start_date is #{start_date.inspect}, end_date is #{end_date.inspect}"
    last_ad_idx = fdw.index {|rec| rec.ad == nil && rec.date <= end_date + 2} || 0
    last_ad_idx -= 1 if fdw[last_ad_idx].ad == nil && last_ad_idx > 0
    # logger.info "graph_data: last_ad_idx #{last_ad_idx}"
    unless last_ad_idx == nil || last_ad_idx < 1
      if fdw[last_ad_idx].date < end_date + 2
        # we're looking at the end of the data, so do 7 "real" days plus two projected
        first_ad_idx = last_ad_idx - 6
        first_ad_idx = 0 if first_ad_idx < 0
        ad_recs = fdw[first_ad_idx,7]
        # logger.info "first_ad_idx #{first_ad_idx}, last_ad_idx #{last_ad_idx}, ad_recs is #{ad_recs.size} long from #{ad_recs[0].date} to #{ad_recs[-1].date}"
        start_date = ad_recs[0].date
        end_date = ad_recs[-1].date
        # logger.info "and dates reset to #{start_date}, #{end_date}"
        @projected_ad_data = FieldDailyWeather.projected_ad(ad_recs)
      else
        # we're looking historically, so do 9 days and no projected
        first_ad_idx = last_ad_idx - 8
        first_ad_idx = 0 if first_ad_idx < 0
        ad_recs = fdw[first_ad_idx,9]
        start_date = ad_recs[0].date
        end_date = ad_recs(-3).date
        @projected_ad_data = []
      end
    end
    @graph_data = ad_recs.collect { |fdw| fdw.ad }
    @dates,@date_str,@date_hash = make_dates(start_date,end_date)
  end
  
  def field_status
    # logger.info "field_status: group #{@group_id} user #{@user_id} farm #{@farm_id} pivot #{@pivot_id} field #{@field_id}"
    @pivot_id,@pivot = get_and_set(Pivot,Farm,@farm_id)
    @field_id,@field = get_and_set(Field,Pivot,@pivot_id)
    if params[:field] && params[:field][:target_ad_pct]
      @field.update_attributes :target_ad_pct => params[:field][:target_ad_pct]
    end
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
      format.json { render :json => {:ad_data => @graph_data,:projected_ad_data => @projected_ad_data,
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
    @et_methods = EtMethod.all.inject({}) {|hash,etm| hash.merge etm[:type] => etm[:id]}.to_json
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
    # logger.info "SET_FARM: setting the ids to #{params[:farm_id]}"
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
    # logger.info "set field with id #{params[:id]}"
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
