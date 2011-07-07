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
  
  def get_and_set(klass,parent_klass,parent_id)
    sym = (klass.to_s.downcase + '_id').to_sym
    id = params[sym] || session[sym]
    unless id
      plural = klass.to_s.downcase + 's'
      parent_obj = parent_klass.find(parent_id)
      first = eval("parent_obj.#{plural}.first")
      id = first[:id] if first
    end
    session[sym] = id
  end
  
  def get_current_ids
    get_group
    puts "no user and group!"; return unless @current_user && @group
    @farm_id = get_and_set(Farm,Group,@group[:id]); return unless @farm_id
  	@pivot_id = get_and_set(Pivot,Farm,@farm_id); return unless @pivot_id
  	@field_id = get_and_set(Field,Pivot,@pivot_id); return unless @field_id
    @crop_id = get_and_set(Crop,Field,@field_id)
  end
  
end
