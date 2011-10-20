class FarmsController < ApplicationController
  COLUMN_NAMES = [:name,:et_method_id,:notes]
  before_filter :ensure_signed_in, :current_user, :get_group, :except => :post_data
  
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
    group_id = @group[:id]
    # FIXME: Don't forget to insert year here!
    @farms = Farm.where(:group_id => group_id).order(:name) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
  # puts "getting farms for group #{group_id}, found #{@farms.size} entries"
    @farms ||= []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @farms }
      format.json { render :json => @farms.to_jqgrid_json([:name,:et_method_id,:notes,:problem,:id], 
                                                             params[:page], params[:rows],@farms.size) }
    end
    
  end # index
  
  def post_data
    if params[:oper] == "del"
      farm = Farm.find(params[:id])
      if farm.group == @group
        farm.destroy
      end
    else
      attribs = {}
      for col_name in COLUMN_NAMES
        attribs[col_name] = params[col_name] unless col_name == :id || col_name == :problem
      end
      if params[:oper] == "add"
        # if no year supplied, use current one
        unless attribs[:year]
          attribs[:year] = Time.now.year
        end
        attribs[:group_id] = @group[:id]
        Farm.create(attribs)
      else
        Farm.find(params[:id]).update_attributes(attribs)
      end
    end
    render :nothing => true
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
