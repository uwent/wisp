class WeatherStationsController < ApplicationController
  before_filter :ensure_signed_in, :get_current_ids, :ensure_group
  
  def pivots_for_group
    Pivot.all.select { |p| p.farm.group_id == @group[:id] }
  end
  # GET /weather_stations
  # GET /weather_stations.xml
  def index
    @weather_stations = WeatherStation.where(:group_id => @group)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @weather_stations }
    end
  end

  # GET /weather_stations/1
  # GET /weather_stations/1.xml
  def show
    @weather_station = WeatherStation.find(params[:id])
    unless @weather_station.group == @group
      flash[:notice] = 'Weather station not found'
      redirect_to(weather_stations_url)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @weather_station }
    end
  end

  # GET /weather_stations/new
  # GET /weather_stations/new.xml
  def new
    @weather_station = WeatherStation.new
    @pivots = pivots_for_group
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @weather_station }
    end
  end

  # GET /weather_stations/1/edit
  def edit
    @weather_station = WeatherStation.find(params[:id])
    @pivots = pivots_for_group
  end

  # POST /weather_stations
  # POST /weather_stations.xml
  def create
    @weather_station = WeatherStation.new(params[:weather_station])
    @weather_station.group = @group

    respond_to do |format|
      if @weather_station.save
        format.html { redirect_to(@weather_station, :notice => 'Weather station was successfully created.') }
        format.xml  { render :xml => @weather_station, :status => :created, :location => @weather_station }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @weather_station.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /weather_stations/1
  # PUT /weather_stations/1.xml
  def update
    @weather_station = WeatherStation.find(params[:id])
    params[:weather_station][:group_id] = @group[:id]
    respond_to do |format|
      if @weather_station.update_attributes(params[:weather_station])
        format.html { redirect_to(@weather_station, :notice => 'Weather station was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @weather_station.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /weather_stations/1
  # DELETE /weather_stations/1.xml
  def destroy
    @weather_station = WeatherStation.find(params[:id])
    if @weather_station.group == @group
      @weather_station.destroy
    end

    respond_to do |format|
      format.html { redirect_to(weather_stations_url) }
      format.xml  { head :ok }
    end
  end
end
