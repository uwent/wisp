class FarmsController < ApplicationController
  COLUMN_NAMES = [:name,:et_method_id,:notes]
  before_filter :ensure_signed_in, :get_current_ids
  
  # GET /farms
  # GET /farms.xml
  def old_index
    gid = @group[:id]
    @farms = Farm.find(:all, :conditions => ['group_id = ?',gid])
        
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @farms }
    end
  end
  # GET /field_daily_weather
  # GET /field_daily_weather.xml
  def index
    get_current_ids
    raise "no group!" unless @group_id
    # if @group then group_id = @group[:id] else group_id = 1 end
    # Now set the current farm
    get_and_set(Farm,Group,@group_id)
    # FIXME: Don't forget to insert year here!
    @farms = Farm.where(:group_id => @group_id).order(:name) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
    @farms ||= []
    @et_methods = EtMethod.all
    clone_year = params[:clone_pivots_to_year] || Time.now.year
    if (@pivots_need_cloning = check_pivots_for_cloning(clone_year))
      @pivots_need_cloning.each { |p| p.clone_for(clone_year) }
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @farms }
      format.json do
        json = @farms.to_jqgrid_json([:name,:et_method_id,:notes,:problem,:act,:group_id,:id], 
                                     params[:page], params[:rows],@farms.size)
        render :json => json
      end
    end
    
  end # index
  
  def post_data
    # logger.info "Session has #{session.size} keys in it"
    # session.each {|key,value| logger.info "session #{key} == #{value}"}
    @group = Group.find(params[:parent_id])
    session[:group_id] = params[:parent_id]
    if params[:oper] == "del"
      farm = Farm.find(params[:id])
      if farm.group == @group
        farm.destroy
        if session[:farm_id] == params[:id] # we just destroyed the current farm
          session.delete(:farm_id)
          get_current_ids
        end
      else
        logger.warn "Attempt to destroy farm #{params[:id]}, whose group #{farm.group} is not #{@group}"  
      end
    else
      attribs = {}
      for col_name in COLUMN_NAMES
        case col_name
        when :id
        when :problem
        when :et_method_id
          attribs[col_name] = params[col_name] if params[col_name]
        else
          attribs[col_name] = params[col_name]
        end
      end
      if params[:oper] == "add"
        # if no year supplied, use current one
        unless attribs[:year]
          attribs[:year] = Time.now.year
        end
        attribs[:name] = 'New Farm'
        # unless @group
          set_parent_id(attribs,params,:group_id,params[:parent_id])          
        # end
        farm = Farm.create(attribs)
      else
        # Don't allow parameters to muck with the hierarchy! The group is set when the "add"
        # operation happens, but farms cannot be moved among groups.
        if attribs[:group_id]
          attribs.delete(:group_id)
        end
        farm = Farm.find(params[:id])
        farm.update_attributes(attribs)
      end
    end
    render :json => ApplicationController.jsonify(farm.attributes)
  end
  
  def problems
    if params[:farm_id]
      @farm = Farm.find(params[:farm_id].to_i)
    end
    @problems = @farm.problems
    render :partial => '/wisp/partials/farm_problems'
  end  

  # GET /farms/1
  # GET /farms/1.xml
  def show
    @farm = Farm.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @farm }
    end
  end

  # GET /farms/new
  # GET /farms/new.xml
  def new
    @farm = Farm.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @farm }
    end
  end

  # GET /farms/1/edit
  def edit
    @farm = Farm.find(params[:id])
  end

  # POST /farms
  # POST /farms.xml
  def create
    @farm = Farm.new(params[:farm])
    @farm.group = @group

    respond_to do |format|
      if @farm.save
        format.html { redirect_to(@farm, :notice => 'Farm was successfully created.') }
        format.xml  { render :xml => @farm, :status => :created, :location => @farm }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @farm.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /farms/1
  # PUT /farms/1.xml
  def update
    @farm = Farm.find(params[:id])
    @farm.group = @group

    respond_to do |format|
      if @farm.update_attributes(params[:farm])
        format.html { redirect_to(@farm, :notice => 'Farm was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @farm.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /farms/1
  # DELETE /farms/1.xml
  def destroy
    @farm = Farm.find(params[:id])
    @farm.destroy

    respond_to do |format|
      format.html { redirect_to(farms_url) }
      format.xml  { head :ok }
    end
  end
end
