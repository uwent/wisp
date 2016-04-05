class UsersController < AuthenticatedController
  before_action :ensure_john!

  def index
  end

  private

  def ensure_john!
    head :forbidden unless current_user.john?
  end
end
