class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticationHelper
  
  private
  def get_group
    puts "get_group: #{@current_user.inspect} Current user's groups: #{@current_user.groups.inspect}"
    @group = @current_user.groups.first
  end
  
  def get_current_ids
    get_group
    raise "NO current group" unless @group
    @farm_id = params[:farm_id] || session[:farm_id] || Farm.my_farms(@group[:id]).first # what to do if no farms yet?
  	@pivot_id = params[:pivot_id] || session[:pivot_id] || (Farm.find(@farm_id).pivots.first || Pivot.new)[:id]
    @field_id = params[:field_id] || session[:field_id] || (Pivot.find(@pivot_id).fields.first || Field.new)[:id]
  end
  
end
