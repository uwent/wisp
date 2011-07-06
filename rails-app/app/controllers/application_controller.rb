class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticationHelper
  
  private
  def get_group
    unless @current_user
      return nil
    end
    # puts "get_group: #{@current_user.inspect} Current user's groups: #{@current_user.groups.inspect}"
    @group = @current_user.groups.first
  end
  
  def get_current_ids
    get_group
    return unless @current_user && @group
    @farm_id = params[:farm_id] || session[:farm_id] || (Farm.my_farms(@group[:id]).first)[:id] # what to do if no farms yet?
  	@pivot_id = params[:pivot_id] || session[:pivot_id] || (Farm.find(@farm_id).pivots.first || Pivot.new)[:id]
    @field_id = params[:field_id] || session[:field_id] || (Pivot.find(@pivot_id).fields.first || Field.new)[:id]
    @crop_id = params[:crop_id] || session[:crop_id] || (Field.find(@field_id).crops.first || Crop.new)[:id]
    # is this really a good idea? Going with it for now...
    session[:group_id] = @group[:id]
    session[:farm_id] = @farm_id
    session[:pivot_id] = @pivot_id
    puts "setting field id in session to #{@field_id}"
    session[:field_id] = @field_id
  end
  
end
