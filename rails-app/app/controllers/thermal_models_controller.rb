require 'net/http'
class ThermalModelsController < ApplicationController
  @@wiDD_server = "www.soils.wisc.edu"
  @@wiDD_path = "/~asig/wiDDs.html"
  @@wiDD_url = "http://#{@@wiDD_server}#{@@wiDD_path}"
  def index
  end

  def degree_days
  end
  
  def corn
  end

  def corn_dev
  end
  
  def ecb
  end
  
  def alfalfa
  end
  
  def corn_stalk_borer
  end

  def potato
  end  
  
  def tree
  end
  
  def gypsy
  end
  
  def gypsyinfo
  end
  
  def wiDDs
    puts @@wiDD_url
    redirect_to @@wiDD_url
  end
  
  def wiDDs_csv
    http = Net::HTTP.new(@@wiDD_server)
    resp,data = http.get(@@wiDD_path,nil)
    first = true
    before_pre = true
    after_pre = false
    lines = []
    data.each do |line|
      line.strip!
      if before_pre
        if line =~ /<pre>/
          before_pre = false
        end
      else
        unless after_pre
          if line =~ /<\/pre>/
            after_pre = true
          elsif first
            # in the first line of the report, replace the blanks with a "Location" header
            lines << "Location,#{line.gsub(/[\s]+([^\s])/,',\1')}"
            first = false
          else
            # convert the text line to CSV.
            lines << line.gsub(/[\s]+([^\s])/,',\1')
          end
        end
      end
    end
    puts lines
    send_data lines.join("\n"), :filename => 'wiDDs.csv'
  end
  
  def westernbeancutworm
  end 
end
