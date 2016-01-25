source 'https://rubygems.org'

gem 'rails', '4.2.5'
gem 'pg'

gem 'asigbiophys', path: 'vendor/asigbiophys'
gem 'calendar_date_select'
gem 'devise'
gem 'jquery-rails'
gem 'will_paginate'

group :development, :staging do
  gem 'mail_safe'
end

group :development, :test do
  gem 'mysqltopostgres', github: 'maxlapshin/mysql2postgres'
  gem 'factory_girl_rails'
  gem 'pry'
  gem 'rspec-rails'
  gem 'valid_attribute'
end

group :test do
  gem 'simplecov', require: false
end
