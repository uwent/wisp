source "https://rubygems.org"

gem "rails", "~> 7.1"
gem "railties", "~> 7.1"
gem "activesupport", "~> 7.1"
gem "pg", "~> 1.5"
gem "devise", "~> 4.9"
gem "whenever", "~> 1.0"
gem "httparty", "~> 0.21"
gem "jbuilder", "~> 2.11"
gem "jqgrid-jquery-rails", "~> 4.6"
gem "jquery-rails", "~> 4.6"
gem "jquery-ui-rails", github: "jquery-ui-rails/jquery-ui-rails"
gem "rails-ujs", "~> 0.1"
gem "sassc-rails", "~> 2.1"
gem "coffee-rails", "~> 5.0"
gem "decent_exposure", "~> 3.0"
gem "will_paginate", "~> 4.0"
gem "net-smtp", "~> 0.4" # required as of ruby 3.1
gem "terser", "~> 1.1" # for JS compression
gem "asigbiophys", path: "vendor/asigbiophys"

group :development do
  gem "puma"
  gem "capistrano"
  gem "capistrano-bundler"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  gem "letter_opener"
  gem "letter_opener_web"
  gem "web-console"
  gem "standard"
end

group :development, :test do
  gem "byebug"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem "rspec-rails"
  gem "spring"
  gem "spring-commands-rspec"
  gem "valid_attribute"
end

group :test do
  gem "simplecov"
  gem "webmock"
end
