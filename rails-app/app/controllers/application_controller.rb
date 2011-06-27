class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticationHelper
  
  private
  def get_group
    puts "get_group: #{@current_user.inspect} Current user's groups: #{@current_user.groups.inspect}"
    @group = @current_user.groups.first
  end
  
  def get_current_ids
    puts "get_current_ids..."
    get_group
    raise "NO current group" unless @group
    @farm_id = params[:farm_id] || session[:farm_id] || (Farm.my_farms(@group[:id]).first)[:id] # what to do if no farms yet?
    raise "No farm" unless @farm_id
  	@pivot_id = params[:pivot_id] || session[:pivot_id] || (Farm.find(@farm_id).pivots.first || Pivot.new)[:id]
  	raise "No pivot" unless @pivot_id
    @field_id = params[:field_id] || session[:field_id] || (Pivot.find(@pivot_id).fields.first || Field.new)[:id]
    raise "No field" unless @field_id
    puts "get_current_ids: group #{@group_id} farm #{@farm_id} pivot #{@pivot_id} field #{@pivot_id}"
    # is this really a good idea? Going with it for now...
    session[:group_id] = @group[:id]; session[:farm_id] = @farm_id; session[:pivot_id] = @pivot_id; session[:field_id] = @field_id
  end
  
end
