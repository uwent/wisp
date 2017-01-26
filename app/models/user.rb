class User < ActiveRecord::Base
  devise \
    :database_authenticatable,
    :recoverable,
    :registerable,
    :rememberable,
    :trackable,
    :validatable

  before_destroy :remove_group_if_group_admin

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  after_create :create_group_and_membership

  def name
    [first_name, last_name].join(' ').strip
  end

  # TODO: Is this used at all?
  def group_description
    "#{name}'s group"
  end

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      User.all.each do |user|
        csv << [user.email]
      end
    end
  end

  private
    def create_group_and_membership
      transaction do
        group = Group.create!(description: group_description)
        memberships.create!(group_id: group.id, is_admin: true)
      end
    end

    def remove_group_if_group_admin
      transaction do
        memberships.each do |membership|
          membership.group.destroy! if membership.is_admin
        end
      end
    end
end
