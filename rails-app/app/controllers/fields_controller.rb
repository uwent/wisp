class FieldsController < ApplicationController
  set_default_filters
 
  COLUMN_NAMES = [:name,:area,:soil_type_id,:field_capacity_pct,:perm_wilting_pt_pct,:target_ad_pct,
                  :ref_et_station_id,:rain_station_id,:soil_moisture_station_id,:notes]
  # GET /fields
  # GET /fields.xml
  def index
    get_current_ids
    @fields = Field.where(:pivot_id => @pivot_id).order(:name) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
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
    @pivot = Pivot.find(params[:parent_id])
    session[:pivot_id] = params[:parent_id]
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
      if attribs[:soil_type_id]
        attribs[:soil_type_id] = attribs[:soil_type_id].to_i
        attribs[:soil_type_id] = SoilType.default_soil_type[:id] if attribs[:soil_type_id] == 0
      end
      if params[:oper] && params[:oper] == "add"
        set_parent_id(attribs,params,:pivot_id,@pivot_id)
        unless attribs[:soil_type_id]
          attribs[:soil_type_id] = SoilType.default_soil_type[:id]
        end
        # Should do a method for this, perhaps with a block for the tests
        unless attribs[:name] && attribs[:name] != ''
          attribs[:name] = "New field"
        end
        field = Field.create(attribs)
      else
        field = Field.find(params[:id])
        attribs = field.groom_for_defaults(attribs)
        field.update_attributes(attribs)
      end
    end
    attrs = field.attributes.symbolize_keys
    attrs[:field_capacity] = field.field_capacity unless attrs[:field_capacity]
    attrs[:perm_wilting_pt] = field.perm_wilting_pt unless attrs[:perm_wilting_pt]
    attrs = ApplicationController.jsonify(attrs)
    render :json => attrs
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
