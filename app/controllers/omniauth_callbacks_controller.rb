class OmniauthCallbacksController < ApplicationController
  def google_oauth2
    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)
 
    if @user.persisted?
      logger.info "user was persisted"
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      session[:user_id] = @user.id
      sign_in_and_redirect @user, :event => :authentication
    else
      logger.info "user not persisted"
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    flash[:error] = "Sorry, authentication has failed. Please contact us for help."
    redirect_to wisp_index_url
  end
  
  # To get the Devise forms moved out into the view hierarchy where you can mess with them:
  # rails g devise:views
end
