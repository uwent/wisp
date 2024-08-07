class WispController < AuthenticatedController
  def index
  end

  # GET
  def project_status
  end

  # GET / POST
  def pivot_crop
    # these variables are the initial values when the page is loaded. After the user
    # starts clicking, all bets are off!
    if params["pivot_id"] && params["pivot_id"] != ""
      @pivot_id = params["pivot_id"]
      @pivot = Pivot.find(@pivot_id)
      @farm = @pivot.farm
      @farm_id = @farm.id
    else
      @pivot = @farm.pivots.order(:name).first
      @pivot_id = @pivot.id
    end
    @field = @pivot.fields.order(:name).first
    @field_id = @field.id
    # @crop_id = @field.current_crop[:id]
    # # @farm = Farm.find(@farm_id) if @farm_id
    # @pivot = Pivot.find(@pivot_id) if @pivot_id
    # @pivots = Pivot.where(:farm_id => @farm_id)
    # @field = Field.find(@field_id) if @field_id
    # @fields = Field.where(:pivot_id => @pivot_id)
    # @crop = Crop.find(@crop_id) if @crop_id
    # @crops = Crop.where(:field_id => @field_id)
    # FIXME: Need to filter everything below pivot for current year
    # if params[:ajax]
    #   render partial: "pivot_setup_grid"
    # end
  end

  # GET / POST
  def field_setup_grid
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot_id, @pivot = get_and_set(Pivot, Farm, @farm_id)
    @pivots = Pivot.where(farm_id: @farm_id)
    # @field = @pivot.fields.first
    # @field_id = @field[:id]
    # @fields = Field.where(:pivot_id => @pivot_id)
    # @crop = Crop.find(@crop_id) if @crop_id
    # @crops = Crop.where(:field_id => @field_id)
    render layout: false
  end

  # GET / POST
  def crop_setup_grid
    @farm = Farm.where(id: @farm_id).first if @farm_id
    @pivot = Pivot.where(id: @pivot_id).first if @pivot_id
    @pivots = Pivot.where(farm_id: @farm_id)
    @field, @field_id = get_and_set(Field, Pivot, @pivot_id)
    @field = Field.where(id: @field_id).first if @field_id
    @fields = Field.where(pivot_id: @pivot_id)
    @crop = @field.current_crop
    @crop_id = @crop[:id]
    @crops = Crop.where(field_id: @field_id)
    render layout: false
  end

  # GET / POST
  def weather
    @weather_stations = @group.weather_stations

    # view will catch empty weather station set
    return render if @weather_stations.empty?

    if params[:weather_station_id]
      wx_stn_id = params[:weather_station_id].to_i
      @weather_station = @weather_stations.detect { |wxs| wxs[:id].to_i == wx_stn_id }
      unless @weather_station
        Rails.logger.info "WispController :: Could not find station #{wx_stn_id} in #{@weather_stations.collect { |e| e[:id] }.inspect}, using first wx stn in group"
        @weather_station = @weather_stations.first
      end
      # Rails.logger.info "Found a station, using #{@weather_station[:id]}"
    else
      Rails.logger.info "WispController :: No wx stn passed, using first wx stn in group"
      @weather_station = @weather_stations.first
    end
    @years = [Time.now.year]
    @year = Time.now.year
    # Check that this year's data are present for this station
    @weather_station.ensure_data_for(@year)
    # set date ranges for determining initial grid page
    @min_date = Date.civil(@year, *Field::START_DATE)
    @max_date = Date.civil(@year, *Field::END_DATE)
    @today = Date.today.clamp(@min_date, @max_date)

    if params[:ajax]
      render layout: false
    end
  end

  # GET
  def lookup
  end

  # GET / POST
  def field_status
    # Rails.logger.info "field_status: group #{@group_id} user #{@user_id} farm #{@farm_id} pivot #{@pivot_id} field #{@field_id}"
    @pivot_id, @pivot = get_and_set(Pivot, Farm, @farm_id)
    @field_id, @field = get_and_set(Field, Pivot, @pivot_id)
    if params[:field] && params[:field][:target_ad_pct]
      @field.update target_ad_pct: params[:field][:target_ad_pct]
    else
      @field.do_balances
    end

    # initial date values for the view
    @min_date = FieldDailyWeather.minimum(:date)
    @max_date = FieldDailyWeather.maximum(:date)
    @today = Date.today.clamp(@min_date, @max_date)
    # @cur_date = (cur_date || @today).clamp(@min_date, @max_date)
    # puts "cur_date #{cur_date}"

    @ad_at_pwp = @field.ad_at_pwp
    field_status_data(params[:cur_date]) # @cur_date may be nil, but will be set if so
    session[:today] = @cur_date
    # now that we've got the last week's fdw recs, check if any need ET
    @ad_recs.each do |adr|
      if adr.ref_et.nil? || adr.ref_et.zero?
        @field.get_et
        @field.get_precip
        break
      end
    end
    # run it around again for degree days
    if @field.need_degree_days?
      @ad_recs.each do |adr|
        if adr.degree_days.nil? || adr.degree_days.zero?
          @field.get_degree_days
          break
        end
      end
    end
    # for some reason, IE makes a request for format JSON, which kinda whacks things. So we explicitly
    # specify the template, which works for everybody.
    # render "field_status.html.erb"
  end

  # GET
  def projection_data
    @field_id = params[:field_id]
    @field = Field.find(@field_id)
    @farm = @field.pivot.farm
    @farm_id = @farm[:id]
    field_status_data(params[:cur_date]) # may be nil
    respond_to do |format|
      format.json {
        render json: {
          ad_data: @graph_data,
          projected_ad_data: @projected_ad_data,
          target_ad_data: @target_ad_data,
          labels: @date_hash
        }
      }
    end
  end

  # GET
  def farm_status
    get_current_ids
    if @farm && !@group_id
      @group_id = @farm.group[:id]
    end
    if params[:ajax]
      render layout: false
    end
  end

  # Ajax-accessible summary/projected box
  def summary_box
    get_current_ids
    @field_id = params[:field_id]
    field_status_data(params[:cur_date])
    render partial: "wisp/field_status__summary_box"
  end

  # GET
  def report_setup
  end

  # POST?
  def set_farm
    # Rails.logger.info "SET_FARM: setting the ids to #{params[:farm_id]}"
    session[:farm_id] = @farm_id = params[:farm_id]
    if @farm_id
      @farm = Farm.find(@farm_id)
    end
    head :ok, content_type: "text/html"
  end

  # POST?
  def set_pivot
    head :ok, content_type: "text/html"
  end

  # POST?
  def set_field
    # Rails.logger.info "set field with id #{params[:id]}"
    if params[:field_id]
      @field_id = params[:field_id]
      @field = Field.find(@field_id)
      session[:field_id] = @field_id
    end
    render json: {field_id: params[:field_id]}
  end

  private

  # Make a line for the Target AD value for this field
  # We just use the length of projected_ad_data EDIT: Didn't work when date was less than a week out from initial date
  def target_ad_data(field, ad_data)
    return nil unless field.target_ad_pct
    days = 9 # x axis length for plot
    ret = []
    days.times { ret << (field.target_ad_pct / 100.0) * field.ad_max }
    ret
  end

  # Given a season-start date of initial_date and (possibly) a point in that
  # season in cur_date, find the start and end of the week encompassing cur_date.
  # If cur_date is nil, use today_or_latest and work from there.
  def date_strs(initial_date, cur_date = nil)
    if cur_date
      begin
        end_date = Date.parse(cur_date)
      rescue => e
        Rails.logger.warn "WispController :: Date reset problem: #{e}. Initial date: #{initial_date}, cur_date: #{cur_date}"
        end_date = today_or_latest(@field_id)
      end
    else
      end_date = today_or_latest(@field_id)
    end
    # So now end_date is provisionally set; find start_date and coerce end_date to
    # week boundaries
    weeks = ((end_date - initial_date).to_i / 7).to_i
    start_date = initial_date + (7 * weeks)
    end_date = start_date + 6
    cur_date ||= start_date.strftime("%Y-%m-%d")
    [start_date, end_date, cur_date]
  end

  # this creates unexpected behavior where the initial date can be in the future and doesn't match what is shown in the data table or the plot (ie before crop emergence)
  def today_or_latest(field_id)
    # field = Field.find(field_id)
    Date.today.clamp(
      FieldDailyWeather.where(field_id:).minimum(:date),
      FieldDailyWeather.where(field_id:).maximum(:date)
    )
    # earliest = field.current_crop.emergence_date
    # query = "select max(date) as date from field_daily_weather where field_id=#{field_id}"
    # latest = FieldDailyWeather.find_by_sql(query).first.date
    # day = Date.today
    # day = earliest if day < earliest
    # day
  end

  def field_status_data(cur_date = nil)
    @field = Field.find(@field_id) if @field_id
    @pivot = Pivot.find(@pivot_id = @field[:pivot_id])
    @farm = Farm.find(@farm_id = @pivot[:farm_id])

    @field_weather_data = @field.field_daily_weather
    @initial_date = @field_weather_data.first.date
    start_date, end_date, @cur_date = date_strs(@initial_date, cur_date)
    # Rails.logger.debug "WispController :: field_status_data: cur_date passed in was #{cur_date}, #{start_date} to #{end_date} at #{@cur_date} for #{@field_id}"
    @ad_recs = FieldDailyWeather.fdw_for(@field_id, start_date, end_date)
    @ad_data = @ad_recs.collect { |fdw| fdw.ad }
    # sets @graph_data, @projected_ad_data,@dates,@date_str,and @date_hash
    graph_data(@field_weather_data, start_date, end_date)
    # Rails.logger.info "field_status_data: cur_date #{@cur_date}, start_date #{start_date.to_s}, end_date #{end_date.to_s}, dates #{@dates.inspect}"
    # Rails.logger.info "field_status_data: fdw is \n#{@ad_recs.collect { |e| [e.date,e.field_id,e.ref_et].join(",") }.join("\n")}"
    # Rails.logger.info "field_status_data: @graph_data is #{@graph_data.inspect}, @projected is #{@projected_ad_data.inspect}, over #{@date_hash.inspect}"
    @summary_data = FieldDailyWeather.summary(@field.id)
    @target_ad_data = target_ad_data(@field, @ad_data)
  end

  # from a set of fdw recs and some idea of where to begin looking, return
  # the graph and summary data. This will be a an array of AD numbers,
  def graph_data(fdw, start_date, end_date, start_projecting = Date.today)
    ad_recs = @ad_recs # just so it's something if we don't reset them
    # reposition the window, if necessary, so that it ends NLT the end of AD data
    # Rails.logger.info "graph_data: start_date is #{start_date.inspect}, end_date is #{end_date.inspect}, #{fdw.size} records"
    first_ad_idx = fdw.index { |rec| rec.ad.nil? } || fdw.index { |rec| rec.date == start_date } || 0
    first_ad_idx = 0 if first_ad_idx < 0
    last_ad_idx = first_ad_idx + 8
    last_ad_idx = fdw.size - 1 if last_ad_idx >= fdw.size
    ad_recs = fdw[(first_ad_idx..last_ad_idx)]
    start_date = ad_recs[0].date
    end_date = ad_recs[-3].date
    @projected_ad_data = []
    # (first_ad_idx..last_ad_idx).each { |idx| @projected_ad_data << (fdw[idx].ref_et == 0.0) }
    @projected_ad_data = fdw[(first_ad_idx..last_ad_idx)].collect { |fdw| fdw.ref_et.zero? }
    @graph_data = ad_recs.collect { |fdw| fdw.ad }
    @dates, @date_str, @date_hash = make_dates(start_date, end_date)
  end

  # Usually start_date will be a week ago and finish_date will be yesterday
  def make_dates(start_date, finish_date)
    day = 0
    dates = []
    date_hash = {}
    date_str = ""
    (start_date..(finish_date + 2)).each do |date|
      dates << date
      if date == Date.today
        date_str += "#{day}: 'Today',"
        date_hash[day] = "Today"
      else
        date_str += "#{day}: '#{date.strftime("%b %d")}',"
        date_hash[day] = date.strftime("%b %d")
      end
      day += 1
    end
    [dates, date_str, date_hash]
  end
end
