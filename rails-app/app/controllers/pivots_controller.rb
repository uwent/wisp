class PivotsController < ApplicationController
  set_default_filters
  # get_current_farm sets farm_id
  before_filter :get_current_farm
  
    COLUMN_NAMES = [
      :name, :latitude, :longitude, :equipment, :pump_capacity,
      :some_energy_rate_metric, :cropping_year, :notes, :act, :farm_id, :id
    ]
  
  # GET /pivots
  # GET /pivots.xml
  def index
    get_current_ids
    @pivots = Pivot.find(:all, :conditions => ['farm_id = ?', @farm_id])
    session[:farm_id] = @farm_id
    @farm = Farm.find(@farm_id)
    @pivot = @pivots.first
    if params[:id]
      begin
        @pivot = @pivots.find { |f| f[:id] == params[:id] }
      rescue
        logger.warn "Attempt to GET nonexistent pivot #{params[:id]}"
      end
    end

    @pivots = Pivot.where(:farm_id => @farm_id).order(:name) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
  # puts "getting pivots for pivot #{@pivot_id}, found #{@pivots.size} entries"
    @pivots ||= []
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pivots }
      columns = COLUMN_NAMES
      format.json { render :json => @pivots.to_jqgrid_json(columns,params[:page], params[:rows],@pivots.size) }
    end
  end

  def post_data
    logger.info "pivot post data for farm #{params[:parent_id]}"
    @farm = Farm.find(params[:parent_id])
    session[:farm_id] = params[:parent_id]
    if params[:oper] == "del"
      pivot = Pivot.find(params[:id])
      # check that we're in the right hierarchy, and not some random id
      if pivot.farm == @farm
        pivot.destroy
      end
    else
      attribs = {}
      for col_name in COLUMN_NAMES
        attribs[col_name] = params[col_name] unless col_name == :id || col_name == :act
      end
      if params[:oper] && params[:oper] == "add"
        attribs[:name] = "New pivot (farm ID: #{@farm[:id]})"
        attribs[:farm_id] = @farm[:id]
        unless attribs[:cropping_year]
          attribs[:cropping_year] = '2012'
        end
        pivot = Pivot.create(attribs)
        logger.info "created the new pivot #{pivot.inspect}"
      else
        attribs.delete(:farm_id) if attribs[:farm_id]
        pivot = Pivot.find(params[:id])
        pivot.update_attributes(attribs)
      end
    end
    render :json => ApplicationController.jsonify(pivot.attributes)
  end

  # GET /pivots/1
  # GET /pivots/1.xml
  def show
    @pivot = Pivot.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @pivot }
    end
  end

  # GET /pivots/new
  # GET /pivots/new.xml
  def new
    @pivot = Pivot.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pivot }
    end
  end

  # GET /pivots/1/edit
  def edit
    @pivot = Pivot.find(params[:id])
  end

  # POST /pivots
  # POST /pivots.xml
  def create
    @pivot = Pivot.new(params[:pivot])
    @pivot.farm_id = @farm_id

    respond_to do |format|
      if @pivot.save
        format.html { redirect_to(@pivot, :notice => 'Pivot was successfully created.') }
        format.xml  { render :xml => @pivot, :status => :created, :location => @pivot }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pivot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pivots/1
  # PUT /pivots/1.xml
  def update
    @pivot = Pivot.find(params[:id])
    @pivot.farm_id = @farm_id

    respond_to do |format|
      if @pivot.update_attributes(params[:pivot])
        format.html { redirect_to(@pivot, :notice => 'Pivot was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pivot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pivots/1
  # DELETE /pivots/1.xml
  def destroy
    @pivot = Pivot.find(params[:id])
    @pivot.destroy

    respond_to do |format|
      format.html { redirect_to(pivots_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  def get_current_farm
    @farm_id = params[:farm_id] || session[:farm_id] || params[:parent_id]
    @farm = Farm.find(@farm_id)
    @group = @farm.group
  end
end
