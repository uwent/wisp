class UsersController < AuthenticatedController
  before_action :ensure_john!

  def index
    @users = User.order(:email).paginate(page: params[:page], per_page: 30)
  end

  private

  def ensure_john!
    head :forbidden unless current_user.john?
  end
end
