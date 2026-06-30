source "https://rubygems.org"

gem "rails", "~> 8.0"
gem "railties", "~> 8.0"
gem "activesupport", "~> 8.0"
gem "pg" # postgres
gem "devise" # logins
gem "whenever" # cron
gem "httparty"
gem "jbuilder"
gem "jqgrid-jquery-rails"
gem "jquery-rails"
gem "jquery-ui-rails", github: "jquery-ui-rails/jquery-ui-rails"
gem "rails-ujs"
gem "sassc-rails"
gem "coffee-rails"
gem "decent_exposure"
gem "will_paginate"
gem "net-smtp" # required as of ruby 3.1
gem "terser" # for JS compression
gem "asigbiophys", path: "vendor/asigbiophys"
gem "csv" # no longer part of the standard libary as of Ruby 3.4
gem "ostruct" # no longer a default gem as of 3.3.6
gem "rack-attack" # rate limiting

group :development do
  gem "puma"
  gem "capistrano"
  gem "capistrano-bundler"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  gem "letter_opener"
  gem "letter_opener_web"
  gem "web-console"
  gem "standard" # linter
  gem "shutup" # easy kill of servers
  gem "ed25519" # for ssh keys
  gem "bcrypt_pbkdf" # for ssh keys
  gem "rails_live_reload" # for live reloading of assets in development
end

group :development, :test do
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "valid_attribute"
end

group :test do
  gem "simplecov"
  gem "webmock"
end
