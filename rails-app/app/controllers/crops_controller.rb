class CropsController < ApplicationController
  before_filter :ensure_signed_in, :current_user, :get_current_ids
  
  # GET /crops
  # GET /crops.xml
  def index
    @crops = Crop.all
	@cropss = Crop.find(:all, :conditions => ['field_id = ?', @field_id])
    session[:farm_id] = @farm_id
    session[:pivot_id] = @pivot_id
	session[:field_id] = @field_id
    @farm = Farm.find(@farm_id)
    @pivot = Pivot.find(@pivot_id)
    @field = Field.find(@field_id)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @crops }
    end
  end

  # GET /crops/1
  # GET /crops/1.xml
  def show
    @crop = Crop.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @crop }
    end
  end

  # GET /crops/new
  # GET /crops/new.xml
  def new
    @crop = Crop.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @crop }
    end
  end

  # GET /crops/1/edit
  def edit
    @crop = Crop.find(params[:id])
  end

  # POST /crops
  # POST /crops.xml
  def create
    @crop = Crop.new(params[:crop])
	@crop.field_id = @field_id

    respond_to do |format|
      if @crop.save
        format.html { redirect_to(@crop, :notice => 'Crop was successfully created.') }
        format.xml  { render :xml => @crop, :status => :created, :location => @crop }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @crop.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /crops/1
  # PUT /crops/1.xml
  def update
    @crop = Crop.find(params[:id])
	@crop.field_id = @field_id

    respond_to do |format|
      if @crop.update_attributes(params[:crop])
        format.html { redirect_to(@crop, :notice => 'Crop was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @crop.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /crops/1
  # DELETE /crops/1.xml
  def destroy
    @crop = Crop.find(params[:id])
    @crop.destroy

    respond_to do |format|
      format.html { redirect_to(crops_url) }
      format.xml  { head :ok }
    end
  end

  private
  def get_current_ids
    group = @current_user.groups.first
    @farm_id = params[:farm_id] || session[:farm_id] || Farm.my_farms(group[:id]).first # what to do if no farms yet?
	@pivot_id = params[:pivot_id] || session[:pivot_id]
	@field_id = params[:field_id] || session[:field_id]
  end
  
end
