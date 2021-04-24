class FieldDailyWeatherController < AuthenticatedController
  MOISTURE_EPSILON = 0.01 # Amount by which an incoming pct moist must differ to be treated as "new"
  PCT_COVER_EPSILON = 0.001 # Likewise for percent cover

  COLUMN_NAMES = [
    :ref_et,
    :rain,
    :irrigation,
    :pct_moisture,
    :entered_pct_cover,
    :ad,
    :notes
    ]

  def moisture_changed?(old,incoming)
    (old - incoming).abs > MOISTURE_EPSILON
  end

  def cover_changed?(old,incoming)
      (old - incoming).abs > PCT_COVER_EPSILON
    end


  # GET /field_daily_weather
  # GET /field_daily_weather.xml
  def index
    page = -1
    page_size = -1
    wx_size = -1
    if params[:irrig_only]
      @field_daily_weather = []
      if params[:id]
        ev = IrrigationEvent.find(params[:id])
        pivot = ev.pivot
        field_ids = pivot.fields.collect do |field|
          qstr = "select '#{field.name}' as field_name,irrigation,id from field_daily_weather "
          qstr += "where date='#{ev.date}' and field_id=#{field.id}"
          @field_daily_weather += FieldDailyWeather.find_by_sql(qstr)
        end
      end
      wx_size = @field_daily_weather.size
      # puts "Irrig only present, found #{@field_daily_weather.size} records"
    else
      field_id = session[:field_id] || session[:field_id] = params[:field_id]
      # FIXME: Shouldn't the date be in here too? I mean, 3 years from now will we be returning 500 records?
      @field_daily_weather = FieldDailyWeather.where(:field_id => field_id).order(:date)
      wx_size = @field_daily_weather.size
      if params[:rows]
        if params[:rows].to_i == 20 # Stupid default value passed, means first refresh
          page_size = 7
          page = FieldDailyWeather.page_for(page_size,@field_daily_weather.first.date)
        else
          page_size = params[:rows].to_i
          page = params[:page] || "-1"
        end
      else
        page = params[:page] || "-1"
      end
      page = page.to_i
      if page == -1
        days = current_day - @field_daily_weather.first.date
        days = 7 if days < 7
        page = days / page_size
      end
      # logger.info "\n****\nfdw#index full; for field_id #{field_id}, page is #{page}, page_size is #{page_size}, #{wx_size} records"; $stdout.flush
      page = 0 if page < 0
      @field_daily_weather = @field_daily_weather.paginate(:page => page, :per_page => page_size)
    end
    @field_daily_weather ||= []
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @field_daily_weather }
      if params[:irrig_only]
        format.json { render :json => @field_daily_weather.to_jqgrid_json([:field_name,:irrigation,:id],
                                                               params[:page] || 1, params[:rows] || 7, wx_size) }
      else
        json = @field_daily_weather.to_jqgrid_json([
          :date,:ref_et,:rain,:irrigation,:display_pct_moisture,:pct_cover_for_json,
          :leaf_area_index, :adj_et_for_json,:ad,:deep_drainage,:id],
          page, page_size, wx_size)
        # logger.info json.inspect
        format.json { render :json => json }
      end
      format.csv do
        # CSVs always start at start of weather data and go through to the bitter end, per John
        season_year = @field_daily_weather.first ? @field_daily_weather.first.date.year : Date.today.year
        start_date = Date.new(season_year,Field::START_DATE[0],Field::START_DATE[1])
        finish_date = Date.new(season_year,Field::END_DATE[0],Field::END_DATE[1])
        @soil_type = ''
        @soil_type = @field_daily_weather.first.field.soil_type.name
        @summary = FieldDailyWeather.summary(field_id,start_date,)
        render :template => 'field_daily_weather/daily_report', :filename => 'field_summary.csv', :content_type => "text/csv"
      end
    end

    def calc_page(fdw,date,page_size)
      days = date - fdw.first.date
      days = 7 if days < 7
      days / page_size
    end

    # in the example, this goes in the block on the query
    # if params[:_search] == "true"
    #   id =~ "%#{params[:id]}%" if params[:id].present?
    #   date =~ "%#{params[:date]}%" if params[:date].present?
    #   ref_et =~ "%#{params[:ref_et]}%" if params[:ref_et].present?
    #   adj_et =~ "%#{params[:adj_et]}%" if params[:adj_et].present?
    #   rain =~ "%#{params[:rain]}%" if params[:rain].present?
    #   irrigation =~ "%#{params[:irrigation]}%" if params[:irrigation].present?
    #   entered_pct_moisture =~ "%#{params[:entered_pct_moisture]}%" if params[:entered_pct_moisture].present?
    #   entered_pct_cover =~ "%#{params[:entered_pct_cover]}%" if params[:entered_pct_cover].present?
    #   leaf_area_index =~ "%#{params[:leaf_area_index]}%" if params[:leaf_area_index].present?
    #   calcualated_pct_moisture =~ "%#{params[:calcualated_pct_moisture]}%" if params[:calcualated_pct_moisture].present?
    #   ad =~ "%#{params[:ad]}%" if params[:ad].present?
    #   deep_drainage =~ "%#{params[:deep_drainage]}%" if params[:deep_drainage].present?
    # end
  end # index

  def post_data
    attribs = {}
    for col_name in COLUMN_NAMES
      attribs[col_name] = params[col_name] unless col_name == :id || col_name == :problem
    end
    fdw = FieldDailyWeather.find(params[:id])
    # logger.info "fdw was #{fdw.inspect}"
    # logger.info "new attribs are #{attribs.inspect}"
    # Percent moisture is special -- if the user entered an updated value, it's sacred
    if attribs[:pct_moisture]
      unless moisture_changed?(attribs[:pct_moisture].to_f,fdw.pct_moisture.to_f) # it's not changing
        attribs.delete(:pct_moisture) # so we don't need to update it and trigger sacredness
      else
        logger.info "new moisture is #{attribs[:pct_moisture].to_f} and old was #{fdw.pct_moisture.to_f}, setting it"
      end
    end
    # Pct cover is special for a different reason -- if the user changes it, we have to call the field's interp
    # routine. Don't bother, though, if it's the same
    do_pct_cover = false
    if attribs[:entered_pct_cover]
      unless cover_changed?(attribs[:entered_pct_cover].to_f,fdw.pct_cover.to_f) # it's not changing
        # logger.info "Cover value supplied is the same as old one, so don't bother"
        attribs.delete(:entered_pct_cover) # so we don't need to update it and trigger sacredness
      else
        # logger.info "new cover is #{attribs[:entered_pct_cover].to_f} and old was #{fdw.pct_cover.to_f}, setting it"
        do_pct_cover = true
      end
    end

    # logger.info "before update_attributes, fdw was #{fdw.inspect}"
    fdw.update(attribs)
    # logger.info "after update_attributes, fdw now #{fdw.inspect}"
    if do_pct_cover
      fdw.field.pct_cover_changed(fdw)
    end
    fdw.field.save! # triggers do_balances

    # DEBUG ONLY
    # fdw = FieldDailyWeather.find(params[:id])
    # logger.info "after field save, fdw now #{fdw.inspect}"

    render :nothing => true
  end

  # GET /field_daily_weather/1
  # GET /field_daily_weather/1.xml
  def show
    @field_daily_weather = FieldDailyWeather.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field_daily_weather }
    end
  end

  # GET /field_daily_weather/new
  # GET /field_daily_weather/new.xml
  def new
    @field_daily_weather = FieldDailyWeather.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field_daily_weather }
    end
  end

  # GET /field_daily_weather/1/edit
  def edit
    @field_daily_weather = FieldDailyWeather.find(params[:id])
  end

  # POST /field_daily_weather
  # POST /field_daily_weather.xml
  def create
    @field_daily_weather = FieldDailyWeather.new(params[:field_daily_weather])

    respond_to do |format|
      if @field_daily_weather.save
        # format.html { redirect_to(@field_daily_weather, :notice => 'Field daily weather was successfully created.') }
        format.html { redirect_to :controller => 'wisp', :action => 'field_status'}
        format.xml  { render :xml => @field_daily_weather, :status => :created, :location => @field_daily_weather }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @field_daily_weather.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /field_daily_weather/1
  # PUT /field_daily_weather/1.xml
  def update
    @field_daily_weather = FieldDailyWeather.find(params[:id])

    respond_to do |format|
      if @field_daily_weather.update(params[:field_daily_weather])
        format.html { redirect_to(@field_daily_weather, :notice => 'Field daily weather was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @field_daily_weather.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /field_daily_weather/1
  # DELETE /field_daily_weather/1.xml
  def destroy
    @field_daily_weather = FieldDailyWeather.find(params[:id])
    @field_daily_weather.destroy

    respond_to do |format|
      format.html { redirect_to(field_daily_weather_index_url) }
      format.xml  { head :ok }
    end
  end
end
