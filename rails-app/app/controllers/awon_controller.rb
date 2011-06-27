class Station < ActiveRecord::Base
end

class Blog < ActiveRecord::Base
end

class AwonController < ApplicationController
  
  def index
    connect
    @blogs = Blog.find(:all, :order => 'date desc')
  end

  def daily_clim
  end

  def daily_soil
  end

  def half_hourly
  end

  def half_hourly_twr
  end

  def five_min_rain
  end
  
  def station_info
    connect
    @stns = Station.find_by_sql('SELECT s.*,min(d.theDate) as first,max(d.theDate) as last FROM `stations` s, `t_411` d WHERE s.id = d.stnid group by d.stnid order by status desc,name')
  end
  
  def graphs
  end
  
  def graphs_soiltemp
  end
  
  def blog
    connect
    @blogs = Blog.find(:all, :order => 'date desc')
  end
  
  def connect
    # Station.establish_connection(:adapter => "mysql2", :host => 'molly.soils.wisc.edu', :username => 'wayne',
    #   :password => 'agem.Data', :database => 'aws')
    # Blog.establish_connection(:adapter => "mysql2", :host => 'molly.soils.wisc.edu', :username => 'wayne',
    #   :password => 'agem.Data', :database => 'aws')   
  end
end
