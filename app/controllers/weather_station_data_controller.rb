class WeatherStationDataController < ApplicationController
  before_filter :ensure_signed_in
  
  # GET /weather_station_data
  # GET /weather_station_data.xml
  def index
    @weather_station_data = WeatherStationData.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @weather_station_data }
    end
  end

  # GET /weather_station_data/1
  # GET /weather_station_data/1.xml
  def show
    @weather_station_data = WeatherStationData.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @weather_station_data }
    end
  end

  # GET /weather_station_data/new
  # GET /weather_station_data/new.xml
  def new
    @weather_station_data = WeatherStationData.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @weather_station_data }
    end
  end

  # GET /weather_station_data/1/edit
  def edit
    @weather_station_data = WeatherStationData.find(params[:id])
  end

  # POST /weather_station_data
  # POST /weather_station_data.xml
  def create
    @weather_station_data = WeatherStationData.new(params[:weather_station_data])

    respond_to do |format|
      if @weather_station_data.save
        format.html { redirect_to(@weather_station_data, :notice => 'Weather station datum was successfully created.') }
        format.xml  { render :xml => @weather_station_data, :status => :created, :location => @weather_station_data }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @weather_station_data.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /weather_station_data/1
  # PUT /weather_station_data/1.xml
  def update
    @weather_station_data = WeatherStationData.find(params[:id])

    respond_to do |format|
      if @weather_station_data.update_attributes(params[:weather_station_data])
        format.html { redirect_to(@weather_station_data, :notice => 'Weather station datum was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @weather_station_data.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /weather_station_data/1
  # DELETE /weather_station_data/1.xml
  def destroy
    @weather_station_data = WeatherStationData.find(params[:id])
    @weather_station_data.destroy

    respond_to do |format|
      format.html { redirect_to(weather_station_data_url) }
      format.xml  { head :ok }
    end
  end
end
