# Load production defaults
require File.expand_path("../production.rb", __FILE__)

# Customize config for staging
Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: ENV["WISP_HOST"] || "dev.wisp.cals.wisc.edu",
    protocol: "https"
  }
end
