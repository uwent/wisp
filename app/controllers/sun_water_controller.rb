class SunWaterController < ApplicationController
  def index
  end

  def insol_east_us
  end

  def insol_west_us
  end

  def insol_model
  end

  def et_wimn
  end

  def et_fl
  end

  def et_model
  end
  
  def spreadsheet_download
    send_file File.dirname(__FILE__) + '/../../public/downloads/ADcosmet.xls'
  end

end
