class User < ApplicationRecord
  devise \
    :database_authenticatable,
    :confirmable,
    :recoverable,
    :registerable,
    :rememberable,
    :trackable,
    :validatable,
    :timeoutable

  before_destroy :remove_group_if_group_admin

  before_validation do
    errors.add(:email, "can't be from a .ru domain") if %r{\w+\.ru$}.match?(email)
  end

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  after_create :create_group_and_membership

  def name
    [first_name, last_name].join(" ").strip
  end

  # TODO: Is this used at all?
  def group_description
    "#{name}'s group"
  end

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[id email first_name last_name created_at updated_at last_sign_in last_sign_in_year admin]
      User.all.each do |user|
        csv << [
          user.id,
          user.email,
          user.first_name,
          user.last_name,
          user.created_at,
          user.updated_at,
          user.last_sign_in_at,
          user.last_sign_in_at.year,
          user.admin
        ]
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
