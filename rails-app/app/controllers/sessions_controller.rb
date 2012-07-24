# after http://blog.sethladd.com/2010/09/ruby-rails-openid-and-google.html
class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  def new
    response.headers['WWW-Authenticate'] = Rack::OpenID.build_header(
        :identifier => "https://www.google.com/accounts/o8/id",
        :required => ["http://axschema.org/contact/email",
                      "http://axschema.org/namePerson/first",
                      "http://axschema.org/namePerson/last"],
        :return_to => session_url,
        :method => 'POST')
    head 401
  end

  def create
    if openid = request.env[Rack::OpenID::RESPONSE]
       case openid.status
       when :success
         ax = OpenID::AX::FetchResponse.from_success_response(openid)
         user = User.where(:identifier_url => openid.display_identifier).first
         user ||= User.new_user(:identifier_url => openid.display_identifier,
                               :email => ax.get_single('http://axschema.org/contact/email'),
                               :first_name => ax.get_single('http://axschema.org/namePerson/first'),
                               :last_name => ax.get_single('http://axschema.org/namePerson/last'))
         session[:user_id] = user.id
         # if user.first_name.blank?
           # redirect_to(user_additional_info_path(user))
         # else
         redirect_to(session[:redirect_to] || root_path)
         # end
       when :failure
         logger.warn 'OpenID auth failed!'
         logger.warn openid.inspect
         render :action => 'problem'
       end
     else
       redirect_to new_session_path
     end
  end

  def destroy
    session[:user_id] = nil
    session.delete(:group_id)
    session.delete(:farm_id)
    session.delete(:pivot_id)
    session.delete(:field_id)
    if params[:redirect]
      redirect_to :controller => params[:redirect]
    else
      redirect_to :controller => 'wisp', :action => :home
    end
  end
  
  def su
    # A no-op unless logged in
    puts "su"
    if session[:user_id]
      # A no-op unless logged in as Rick
      if User.find(session[:user_id]).identifier_url == @rick_identifier_url
        session[:user_id] = params[:su_to]
        session.delete(:group_id)
        session.delete(:farm_id)
        session.delete(:pivot_id)
        session.delete(:field_id)
      else
        puts 'wrong person tried to su'
      end
    else
      puts 'no one signed in'
    end
    puts "su'd to #{session[:user_id]}"
    redirect_to(:back)
  end
 
end
