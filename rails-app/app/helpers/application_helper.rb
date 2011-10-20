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
end
