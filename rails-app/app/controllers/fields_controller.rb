class FieldsController < ApplicationController
  set_default_filters
 
  COLUMN_NAMES = [:name,:area,:soil_type,:field_capacity,:perm_wilting_pt,:target_ad_pct,
                  :ref_et_station_id,:rain_station_id,:soil_moisture_station_id,:notes]
  # GET /fields
  # GET /fields.xml
  def index
	@fields = Field.find(:all, :conditions => ['pivot_id = ?', @pivot_id])
    session[:farm_id] = @farm_id
    session[:pivot_id] = @pivot_id
    @farm = Farm.find(@farm_id)
    @pivot = Pivot.find(@pivot_id)
    if params[:field_id]
      @field = @fields.find { |f| f[:id] == params[:field_id] } || @fields.first
    else
      @field = @fields.first
    end
	
    @fields = Field.where(:pivot_id => @pivot_id).order(:name) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
  # puts "getting fields for pivot #{@pivot_id}, found #{@fields.size} entries"
    @fields ||= []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
      columns = COLUMN_NAMES; columns << :id; columns << :pivot_id
      format.json do
        json = @fields.to_jqgrid_json(columns,params[:page], params[:rows],@fields.size)
        render :json => json
      end
    end
  end

  def post_data
    if params[:oper] == "del"
      field = Field.find(params[:id])
      # check that we're in the right hierarchy, and not some random id
      if field.pivot == @pivot
        field.destroy
        if session[:field_id] == params[:id] # we just destroyed the current field
          session.delete(:field_id)
          get_current_ids
        end
      else
        logger.warn "Attempt to destroy field #{params[:id]}, whose pivot #{field.pivot} is not #{@pivot}"
      end
    else
      attribs = {}
      for col_name in COLUMN_NAMES
        attribs[col_name] = params[col_name] unless col_name == :id
      end
      if params[:oper] && params[:oper] == "add"
        attribs[:pivot_id] = @pivot_id
        Field.create(attribs)
      else
        Field.find(params[:id]).update_attributes(attribs)
      end
    end
    render :nothing => true
  end

  # GET /fields/1
  # GET /fields/1.xml
  def show
    @field = Field.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/new
  # GET /fields/new.xml
  def new
    @field = Field.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/1/edit
  def edit
    @field = Field.find(params[:id])
  end

  # POST /fields
  # POST /fields.xml
  def create
    @field = Field.new(params[:field])
	@field.pivot_id = @pivot_id
	
    respond_to do |format|
      if @field.save
        format.html { redirect_to(@field, :notice => 'Field was successfully created.') }
        format.xml  { render :xml => @field, :status => :created, :location => @field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fields/1
  # PUT /fields/1.xml
  def update
    @field = Field.find(params[:id])
	@field.pivot_id = @pivot_id

    respond_to do |format|
      if @field.update_attributes(params[:field])
        format.html { redirect_to(@field, :notice => 'Field was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fields/1
  # DELETE /fields/1.xml
  def destroy
    @field = Field.find(params[:id])
    @field.destroy

    respond_to do |format|
      format.html { redirect_to(fields_url) }
      format.xml  { head :ok }
    end
  end

  
end
