class FieldDailyWeatherController < ApplicationController
  before_filter :ensure_signed_in
  protect_from_forgery :except => [:post_data]
  
  # GET /field_daily_weather
  # GET /field_daily_weather.xml
  def index
    field_id = session[:field_id] || session[:field_id] = params[:field_id]
    @field_daily_weather = FieldDailyWeather.where(:field_id => field_id).order(:date) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
    puts "getting daily wx for field #{field_id}, found #{@field_daily_weather.size} entries"
    @field_daily_weather ||= []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @field_daily_weather }
      format.json { render :json => @field_daily_weather.to_jqgrid_json([:id,:date,:ref_et,:adj_et,:rain,:irrigation,
                                                                         :pct_moisture,:entered_pct_cover,
                                                                         :entered_leaf_area_index,
                                                                         :ad,:deep_drainage], 
                                                             params[:page], params[:rows],@field_daily_weather.size) }
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
    #   entered_leaf_area_index =~ "%#{params[:entered_leaf_area_index]}%" if params[:entered_leaf_area_index].present?
    #   calcualated_pct_moisture =~ "%#{params[:calcualated_pct_moisture]}%" if params[:calcualated_pct_moisture].present?
    #   ad =~ "%#{params[:ad]}%" if params[:ad].present?
    #   deep_drainage =~ "%#{params[:deep_drainage]}%" if params[:deep_drainage].present?
    # end
  end # index
  
  def post_data
    field_daily_weather_params = { :rain => params[:rain], :irrigation=> params[:irrigation],
      :entered_pct_moisture => params[:entered_pct_moisture],
      :entered_pct_cover => params[:entered_pct_cover],
      :entered_leaf_area_index => params[:entered_leaf_area_index] }
      FieldDailyWeather.find(params[:id]).update_attributes(field_daily_weather_params)
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
        format.html { redirect_to(@field_daily_weather, :notice => 'Field daily weather was successfully created.') }
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
      if @field_daily_weather.update_attributes(params[:field_daily_weather])
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
