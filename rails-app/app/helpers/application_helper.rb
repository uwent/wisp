module ApplicationHelper
  def date_selectors(opts={})
    @yesterday = 1.day.ago
    opts = opts_with_defaults opts, {:names => %w(startyear startmonth startday), :first_year => 2000, :day => @yesterday.day, :sep_str => " "}
    
    year_select =  select_tag(opts[:names][0], options_for_select(opts[:first_year]..@yesterday.year, @yesterday.year))
    month_select = my_select_month(@yesterday,opts)
    day_select = select_tag(opts[:names][2], options_for_select(1..31, opts[:day]))
    "#{year_select}#{opts[:sep_str]}#{month_select}#{opts[:sep_str]}#{day_select}".html_safe
  end
  
  def coord_select_options(start=42.0,finish=50.0,step=0.4)
    @coords = []; (start).step(finish,step) {|coord| @coords << coord }
    options_for_select @coords
  end
  
  def opts_with_defaults(opts,defaults)
    new_opts={}
    defaults.keys.each {|defkey| new_opts[defkey] = opts[defkey] || defaults[defkey]}
    new_opts
  end

  private
  
  def my_select_month(date,opts)
    fix_month_fieldname(select_month(date,:use_short_month => true),opts)
  end
  
  def fix_month_fieldname(str,opts)
    str.gsub("name=\"date[month]","name=\"#{opts[:names][1]}")
  end
  
  def abr(date)
    if date
      date.strftime('%D')
    else
      ""
    end
  end
  
  def image_folder_path(folder)
    path = image_path(folder)
    path.gsub(/[^\d][\d]+$/,'')
  end
  
  def merge_usuals(args)
    puts "merge_usuals: @user #{@user}, @user_id #{@user_id}, @current_user #{@current_user}"
    args.merge(
      :user_id => @user || @current_user,
      :group_id => @group,
      :farm_id => @farm,
      :pivot_id => @pivot,
      :field_id => @field,
      :crop_id => @crop
      )
  end
  
  def url_with_usuals(args)
    url_for(merge_usuals(args))
  end
  
  def grid_data_url(what,parent_object)
    url_with_usuals :controller => what.to_s, :q => 1, :parent_id => parent_object
  end
  
  def grid_post_data_url(what,parent_object)
    url_with_usuals :controller => what.to_s, :action  => :post_data, :parent_id => parent_object
  end
end
