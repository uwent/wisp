module AuthenticationHelper
  USING_OPENID = !('true' == ENV['OFFLINE'])
  SINGLE_USER_ID = 1
  # for some reason Devise is passing an argument consisting of a symbol :user to this. ???
  def signed_in?(user=nil)
    logger.info "signed_in?: session[:user_id] is #{session[:user_id]}"
    !session[:user_id].nil?
  end
  
  def ensure_signed_in
    logger.info "ensure_signed_in"
    if USING_OPENID
      unless session[:user_id]
        authenticate_user!
        unless @user
          logger.warn 'NO USER!'
        end
        # FIXME: need to get the authenticated user and set session[:user_id] here
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
