class User < ActiveRecord::Base
  devise \
    :database_authenticatable,
    :recoverable,
    :registerable,
    :rememberable,
    :trackable,
    :validatable

  # TODO: Use strong params
  attr_accessible \
    :email,
    :password,
    :password_confirmation,
    :remember_me

  has_many :memberships
  has_many :groups, through: :memberships

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
end
