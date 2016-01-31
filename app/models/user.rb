class User < ActiveRecord::Base
  devise \
    :database_authenticatable,
    :recoverable,
    :registerable,
    :rememberable,
    :trackable,
    :validatable

  has_many :memberships
  has_many :groups, through: :memberships

  after_create :create_group_and_membership

  def name
    [first_name, last_name].join(' ').strip
  end

  # TODO: Is this used at all?
  def group_description
    "#{name}'s group"
  end

  private

  def create_group_and_membership
    transaction do
      group = Group.create!(description: group_description)
      memberships.create!(group_id: group.id, is_admin: true)
    end
  end
end
