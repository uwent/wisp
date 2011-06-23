module WeatherHelper
  include ApplicationHelper
  def date_selector(var,var_name,field_name)
    current_val = var ? var.strftime(CalendarDateSelect.format[:date]) : 'No'
    "#{calendar_date_select(var_name,field_name,{:size => 18, :value => current_val})}"
  end
  
  def todays_hyd_link
    yesterday = 1.days.ago
    year = yesterday.year
    doy = sprintf("%03d",yesterday.yday)
    "<a href='http://www.soils.wisc.edu/uwex_agwx_data/opu/data/opu#{year}#{doy}' " +
      "class='bar-lit'>Yesterday's report</a>"
  end
  
  def webcam_archive_link(title,opts={},tag_opts={})
    opts = opts_with_defaults(opts,{:days_ago => 0, :movie => false})
    theday = opts[:days_ago].days.ago
    year = theday.year
    month = sprintf("%02d",theday.month)
    day = sprintf("%02d",theday.day)
    if opts[:movie]
      movie = 'movie.html'
    else
      movie = ''
    end
    if tag_opts
      tag_opt_str = tag_opts.inject('') {|str,pair| str += " #{pair[0].to_s}='#{pair[1]}'"}
    end
    "<a href='http://www.soils.wisc.edu/~asig/webcam/archive/" +
      "#{year}/#{month}/#{day}/#{movie}'#{tag_opt_str}>#{title}</a>"
  end
  
end
