class AuthenticatedController < ApplicationController
  # before_filter :authenticate_user!
  before_action :authenticate_user!

  # TODO: Remove this
  # before_filter :get_current_ids
  before_action :get_current_ids

  def current_group
    current_user.groups.first
  end
end
