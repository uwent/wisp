module AuthenticationHelper
  USING_OPENID = false
  SINGLE_USER_ID = 1
  def signed_in?
    logger.info "signed_in?: session[:user_id] is #{session[:user_id]}"
    !session[:user_id].nil?
  end
  
  def current_user
  	if signed_in?
  		@current_user ||= User.find(session[:user_id])
  	else
  		@current_user = nil
  	end
    @current_user
  end
  
  def ensure_signed_in
    # puts "ensure_signed_in"
    if USING_OPENID
      unless signed_in?
        session[:redirect_to] = request.request_uri
        redirect_to(new_session_path)
      end
    else
      session[:user_id] = SINGLE_USER_ID
    end
  end
end
