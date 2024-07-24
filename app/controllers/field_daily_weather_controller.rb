class FieldDailyWeatherController < AuthenticatedController
  CHANGE_EPSILON = 0.00001 # small nonzero value to indicate user has entered a zero, distinct from the true zero default value for rainfall
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

  # GET /field_daily_weather
  def index
    # only json/csv formats allowed
    return redirect_to "/wisp/field_status" if request.format.html?

    page = -1
    page_size = -1
    wx_size = -1

    field_id = session[:field_id] || session[:field_id] = params[:field_id]
    # FIXME: Shouldn't the date be in here too? I mean, 3 years from now will we be returning 500 records?
    @field_daily_weather = FieldDailyWeather.where(field_id: field_id).order(:date)
    wx_size = @field_daily_weather.size
    if params[:rows]
      if params[:rows].to_i == 20 # Stupid default value passed, means first refresh
        page_size = 7
        page = FieldDailyWeather.page_for(page_size, @field_daily_weather.first.date)
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
    page = 1 if page < 1
    @field_daily_weather = @field_daily_weather.paginate(page: page, per_page: page_size)

    respond_to do |format|
      format.json do
        json = @field_daily_weather.to_a.to_jqgrid_json(
          [:date, :ref_et, :rain, :irrigation, :display_pct_moisture, :pct_cover_for_json, :leaf_area_index, :adj_et_for_json, :ad, :deep_drainage, :id],
          page,
          page_size,
          wx_size
        )
        render json: json
      end
      format.csv do
        @field_daily_weather = @field_daily_weather.where("date <= ?", Date.today)
        start_date = @field_daily_weather.first.date
        finish_date = [@field_daily_weather.last.date, Date.today].min
        # season_year = @field_daily_weather.first ? @field_daily_weather.first.date.year : Date.today.year
        # start_date = Date.new(season_year, Field::START_DATE[0], Field::START_DATE[1])
        @soil_type = @field_daily_weather.first.field.soil_type.name
        @summary = FieldDailyWeather.summary(field_id, start_date, finish_date)
        render template: "field_daily_weather/daily_report", filename: "field_summary", content_type: "text/csv", format: :csv
        Rails.logger.info "FDW Controller :: Rendered CSV"
      end
    rescue => e
      Rails.logger.error "FieldDailyWeatherController :: index >> #{e.message}"
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
  end

  # POST /field_daily_weather/post_data
  def post_data
    attribs = {}
    COLUMN_NAMES.each do |col_name|
      # the .empty? catches if a cell was left blank and then submitted
      attribs[col_name] = params[col_name] unless col_name == :id || col_name == :problem || params[col_name]&.empty?
    end
    attribs.compact!
    fdw = FieldDailyWeather.find(params[:id])
    # logger.info "fdw was #{fdw.inspect}"
    # logger.info "new attribs are #{attribs.inspect}"

    # Percent moisture is special -- if the user entered an updated value, it's sacred
    if attribs[:pct_moisture]
      if moisture_changed?(attribs[:pct_moisture].to_f, fdw.pct_moisture.to_f)
        Rails.logger.info "FDWController :: New moisture is #{attribs[:pct_moisture].to_f} and old was #{fdw.pct_moisture.to_f}, setting it"
      else # it's not changing
        attribs.delete(:pct_moisture) # so we don't need to update it and trigger sacredness
      end
    end

    # Pct cover is special for a different reason -- if the user changes it, we have to call the field's interp
    # routine. Don't bother, though, if it's the same
    do_pct_cover = false
    if attribs[:entered_pct_cover]
      if cover_changed?(attribs[:entered_pct_cover].to_f, fdw.pct_cover.to_f)
        # logger.info "new cover is #{attribs[:entered_pct_cover].to_f} and old was #{fdw.pct_cover.to_f}, setting it"
        do_pct_cover = true
      else # it's not changing
        # logger.info "Cover value supplied is the same as old one, so don't bother"
        attribs.delete(:entered_pct_cover) # so we don't need to update it and trigger sacredness
      end
    end

    # logger.info "before update_attributes, fdw was #{fdw.inspect}"
    # logger.info "attributes are #{attribs.inspect}"
    attribs[:rain] = CHANGE_EPSILON if attribs[:rain] && attribs[:rain].to_f.zero? # set rain to small nonzero value if user enters a zero because any true zeros are refreshed from agweather
    fdw.update(attribs)
    # logger.info "after update_attributes, fdw now #{fdw.inspect}"
    if do_pct_cover
      fdw.field.pct_cover_changed(fdw)
    end
    fdw.field.save! # triggers do_balances

    # DEBUG ONLY
    # fdw = FieldDailyWeather.find(params[:id])
    # logger.info "after field save, fdw now #{fdw.inspect}"

    head :ok, content_type: "text/html"
  end

  private

  def calc_page(fdw, date, page_size)
    days = date - fdw.first.date
    days = 7 if days < 7
    days / page_size
  end

  def moisture_changed?(old, incoming)
    (old - incoming).abs > MOISTURE_EPSILON
  end

  def cover_changed?(old, incoming)
    (old - incoming).abs > PCT_COVER_EPSILON
  end
end
