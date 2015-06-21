class WelcomeController < ApplicationController
  def index

  end

  def guide
    send_file Rails.root.join('public', 'USERS_GUIDE.pdf')
  end
end
