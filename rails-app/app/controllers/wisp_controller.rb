class WispController < ApplicationController
  before_filter :ensure_signed_in, :except => [:index]
  before_filter :current_user, :get_group, :get_current_ids
  def index
  end

  def pivot_crop
  end

  def weather
  end

  def lookup
  end

  def field_status
    puts "field_status"
    @farm = Farm.find(@farm_id) if @farm_id
    @pivot = Pivot.find(@pivot_id) if @pivot_id
    @field = Field.find(@field_id) if @field_id
    logger.info @farm_id
    logger.info @field_id
    logger.info @pivot_id
  end

  def farm_status
  end

  def report_setup
  end

end
