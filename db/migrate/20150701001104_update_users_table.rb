class UpdateUsersTable < ActiveRecord::Migration
  def change
    execute(
    <<-sql
      update users
      set email = orig_email,
      orig_email = null
      where orig_email is not null
      and orig_email <> ''
      and (email is null or email = '')
    sql
    )

    User
      .group(:email)
      .select(:email)
      .having('count(*) > 1')
      .each do |user|

      User
        .where(email: user.email)
        .order(:updated_at)
        .each_with_index do |user, index|

        user.email = "#{user.email} ##{index + 1}"
        user.save!(validate: false)
      end
    end

    change_column :users, :email, :string, null: false, default: nil
    change_column :users, :encrypted_password, :string, limit: nil, null: false, default: nil

    remove_column :users, :orig_email
    remove_column :users, :provider
    remove_column :users, :uid
    remove_column :users, :identifier_url

    add_index :users, :email, unique: true unless index_exists?(:users, :email, unique: true)
  end
end
