class Membership < ApplicationRecord
  # TODO: validates
  belongs_to :group
  belongs_to :user

  def self.admin
    where(is_admin: true)
  end
end
