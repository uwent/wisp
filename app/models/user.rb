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
  has_many :plants, through: :crops

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
      "Created" => created_at,
      "Confirmed" => confirmed_at,
      "Last sign in" => current_sign_in_at,
      "Farms" => farms.size,
      "Pivots" => pivots.size,
      "Fields" => fields.size,
      "Crops" => plants.distinct.size,
      "Crop types" => (plants.distinct.size == 0) ? "None" : plants.distinct.pluck(:name).sort.join(", ")
    }.merge(location_info)
  end

  def location_info
    return {} unless pivots.size > 0
    lats = pivots.pluck(:latitude).compact
    lngs = pivots.pluck(:longitude).compact
    ranges = [(lats.max - lats.min).round(1), (lngs.max - lngs.min).round(1)]
    {
      "Centroid" => [(lats.sum / lats.size).round(2), (lngs.sum / lngs.size).round(2)],
      "Ranges" => ranges,
      "Area" => "#{ranges[0] * 10} km x #{ranges[1] * 8} km"
    }
  rescue => e
    Rails.logger.error "Failed to calculate location attributes for user #{id}: #{e.message}"
    {}
  end

  def farm_structure
    farms.collect do |farm|
      {
        name: farm.name,
        pivots: farm.pivots.collect do |pivot|
          {
            name: pivot.name,
            coordinates: [pivot.latitude, pivot.longitude].join(", "),
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
