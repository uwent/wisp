class UsersController < AuthenticatedController
  before_action :ensure_admin!

  def index
    @users = User.order(:email).paginate(page: params[:page], per_page: 30)

    respond_to do |format|
      format.html
      format.csv { send_data User.to_csv, filename: "wisp-users-#{Date.today}.csv" }
    end
  end

  def destroy
    @user = User.find(params[:id])
    old_email = @user.email
    if @user.destroy
      redirect_to users_path, alert: "User #{old_email} removed."
    else
      redirect_to users_path, alert: "ERROR: Unable to remove #{old_email}."
    end
  end

  private

  def ensure_admin!
    head :forbidden unless current_user.admin?
  end
end
