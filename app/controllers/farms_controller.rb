class FarmsController < ApplicationController
  before_filter :ensure_signed_in, :current_user, :get_group
  
  # GET /farms
  # GET /farms.xml
  def index
    gid = @group[:id]
    @farms = Farm.find(:all, :conditions => ['group_id = ?',gid])
        
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @farms }
    end
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
