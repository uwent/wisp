class AuthenticatedController < ApplicationController
  before_filter :authenticate_user!

  # TODO: Remove this
  before_filter :get_current_ids
end
