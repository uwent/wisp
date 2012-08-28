module AuthenticationHelper
  USING_OPENID = true
  SINGLE_USER_ID = 1
  def signed_in?
    logger.info "signed_in?: session[:user_id] is #{session[:user_id]}"
    !session[:user_id].nil?
  end
  
  def current_user
  	if signed_in?
  		@user ||= User.find(session[:user_id])
  	else
  		@user = nil
  	end
    @user
  end
  
  def ensure_signed_in
    logger.info "ensure_signed_in"
    if USING_OPENID
      unless signed_in?
        session[:redirect_to] = request.fullpath
        redirect_to(new_session_path)
      end
    else
      session[:user_id] = SINGLE_USER_ID
    end
    if session[:new_login]
      @new_login = true
      session[:new_login] = false
    else
      @new_login = false
    end
  end
end
