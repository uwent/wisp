class FarmsController < AuthenticatedController
  # skip_before_action :verify_authenticity_token, only: :post_data

  COLUMN_NAMES = [:name, :notes]

  # GET /farms returns JSON
  def index
    return redirect_to "/wisp/farm_status" if request.format.html?

    get_current_ids
    raise "no group!" unless @group_id
    # Now set the current farm
    get_and_set(Farm, Group, @group_id)
    @farms = Farm.where(group_id: @group_id).order(:name) do
      paginate page: params[:page], per_page: params[:rows]
    end
    Rails.logger.warn "FarmsController :: No farms for group #{@group_id} found!" unless @farms && @farms.size > 0
    @farms ||= []

    render json: @farms.to_a.to_jqgrid_json(
      [:name, :notes, :problem, :act, :group_id, :id],
      params[:page],
      params[:rows],
      @farms.size
    )
  rescue => e
    Rails.logger.error "FarmsController :: Index >> #{e.message}"
  end

  # POST /farms/post_data
  def post_data
    @group = current_group
    session[:group_id] = params[:parent_id]
    if params[:oper] == "del"
      farm = @group.farms.find(params[:id])
      if farm.group == @group
        farm.destroy
        if session[:farm_id] == params[:id] # we just destroyed the current farm
          session.delete(:farm_id)
          get_current_ids
        end
      else
        Rails.logger.warn "FarmsController :: Attempt to destroy farm #{params[:id]}, whose group #{farm.group} is not #{@group}"
      end
    else
      attribs = {}
      COLUMN_NAMES.each do |col_name|
        case col_name
        # when :id
        when :problem
          attribs[col_name] = params[col_name] if params[col_name]
        else
          attribs[col_name] = params[col_name]
        end
      end
      if params[:oper] == "add"
        # if no year supplied, use current one
        unless attribs[:year]
          attribs[:year] = Time.now.year
        end
        # unless @group
        set_parent_id(attribs, params, :group_id, params[:parent_id])
        # end
        farm = current_group.farms.create(attribs)
      else
        # Don't allow parameters to muck with the hierarchy! The group is set when the "add"
        # operation happens, but farms cannot be moved among groups.
        if attribs[:group_id]
          attribs.delete(:group_id)
        end
        farm = Farm.find(params[:id])
        farm.update(attribs)
      end
    end
    render json: ApplicationController.jsonify(farm.attributes)
  end

  def problems
    @farms = if params[:farm_id]
      [Farm.where(id: params[:farm_id].to_i)]
    else
      @user.groups.collect { |g| g.farms }.flatten
    end
    # Add farm name to problems structure
    @problems = @farms.collect { |f| f.problems }.flatten
    render partial: "/wisp/farm_problems"
  end
end
