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
  has_many :farms, through: :groups
  has_many :pivots, through: :farms
  has_many :fields, through: :pivots
  has_many :crops, through: :fields

  after_create :create_group_and_membership

  def name
    [first_name, last_name].join(" ").strip
  end

  # TODO: Is this used at all?
  def group_description
    "#{name}'s group"
  end

  def attributes
    {
      "ID" => id,
      "Email" => email,
      "Admin" => admin,
      "Created" => days_ago(created_at),
      "Confirmed" => days_ago(confirmed_at),
      "Last sign in" => days_ago(current_sign_in_at),
      "Farms" => farms.size,
      "Pivots" => pivots.size,
      "Fields" => fields.size,
      "Crops" => crops.pluck(:plant_id).uniq.size
    }
  end

  def farm_structure
    farms.collect do |farm|
      {
        name: farm.name,
        pivots: farm.pivots.collect do |pivot|
          {
            name: pivot.name,
            fields: pivot.fields.collect do |field|
              {
                name: field.name,
                crop: field.crops.first.plant.name
              }
            end
          }
        end
      }
    end
  end


  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[id email created confirmed updated last_sign_in farms pivots fields admin]
      User.all.order(:id).each do |user|
        csv << [
          user.id,
          user.email,
          user.created_at&.to_date,
          user.confirmed_at&.to_date,
          user.updated_at&.to_date,
          user.current_sign_in_at&.to_date,
          user.farms.size,
          user.pivots.size,
          user.fields.size,
          user.admin
        ]
      end
    end
  end

  private

  def days_ago(date)
    date = date.to_date
    "#{date} (#{(Date.today - date).to_i} days ago)"
  rescue
    ""
  end

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
