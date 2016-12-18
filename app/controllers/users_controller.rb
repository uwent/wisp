class UsersController < AuthenticatedController
  before_action :ensure_admin!

  def index
    @users = User.order(:email).paginate(page: params[:page], per_page: 30)
  end

  private

  def ensure_admin!
    head :forbidden unless current_user.admin?
  end
end
