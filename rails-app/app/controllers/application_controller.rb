class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticationHelper
  
  private
  def get_group
    unless @current_user
      return nil
    end
    @group = @current_user.groups.first
  end
  
  def get_and_set(klass,parent_klass,parent_id)
    klassname = klass.to_s.downcase
    sym = (klassname + '_id').to_sym
    id = params[sym] || session[sym]
    if id
      # puts "get_and_set: found the id for #{klass.to_s} in either params (#{params[sym]}) or session (#{session[sym]})"
      # puts "get_and_set: what about string key? (#{params.inspect})"
      obj = klass.find(id)
    else
      plural = klass.to_s.downcase + 's'
      parent_obj = parent_klass.find(parent_id)
      obj = eval("parent_obj.#{plural}.first")
      id = obj[:id] if obj
    end
    session[sym] = id
    [id,obj]
  end
  
  def get_current_ids
    get_group
    unless @current_user
      puts "get_current_ids: no user!"
      return 
    end
    unless @group
      puts "get_current_ids: no group!"
      return
    end
    @farm_id,@farm = get_and_set(Farm,Group,@group[:id]); return unless @farm_id
    # puts "get_current_ids: @farm is #{@farm.name}"
  	@pivot_id,@pivot = get_and_set(Pivot,Farm,@farm_id); return unless @pivot_id
  	@field_id,@field = get_and_set(Field,Pivot,@pivot_id); return unless @field_id
    @crop_id,@crop = get_and_set(Crop,Field,@field_id)
  end
  
end
