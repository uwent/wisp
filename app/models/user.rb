class User < ActiveRecord::Base
  devise \
    :database_authenticatable,
    :recoverable,
    :registerable,
    :rememberable,
    :trackable,
    :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  has_many :memberships
  has_many :groups, :through => :memberships
  devise :omniauthable
  
  def name
    "#{first_name} #{last_name}"
  end
  
  # new_user wraps the User.create! method, so that every user has a group created for them
  # for which they are the admin.
  def self.new_user(arg_hash)
    users_name = "#{arg_hash[:first_name]} #{arg_hash[:last_name]}"
    my_group = Group.create!(:description => users_name + "'s group")
    user = create!(arg_hash)
    membership = Membership.create!(:user_id => user[:id], :group_id => my_group[:id],
                                    :is_admin => true)
    user # return whatever User.create! does
  end
  
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    logger.info "User find_for_google_oauth2: got back #{data.inspect}"
    user = User.where(:provider => access_token.provider, :uid => access_token.uid ).first
    if user
      logger.info "ffgo: Found them by provider and uid"
      return user
    else
      registered_user = User.where(:email => access_token.info.email).first
      if registered_user
        logger.info "ffgo: Found them by email"
        return registered_user
      # added rw 20 April: look also for user whose "orig_mail" matches, they haven't authenticated
      # with new system yet. Update their record to set provide, uid, and email.
      elsif (registered_user = User.where(orig_email: data["email"]).first)
        registered_user.email = registered_user.orig_email
        registered_user.provider = access_token.provider
        registered_user.uid = access_token.uid
        registered_user.save!
        logger.info "ffgo: Found them by orig_email"
        return registered_user
      else
        logger.info "ffgo: Creating them"
        user = User.new_user(
          last_name: data["last_name"],
          first_name: data["first_name"],
          provider: access_token.provider,
          email: data["email"],
          uid: access_token.uid ,
          password: Devise.friendly_token[0,20],
        )
      end
   end
  end
end
