source 'https://rubygems.org'

gem 'rails', '~> 3.1'

gem 'asigbiophys', path: 'vendor/asigbiophys'
gem 'capistrano', '~> 2.15'
gem 'devise'
gem 'jquery-rails'
gem 'omniauth'
gem 'omniauth-google-oauth2'

group :development, :test do
  gem 'mongrel', '1.2.0.pre2'
  gem 'sqlite3'
end

group :test do
  gem 'simplecov', require: false
end

group :production do
  gem 'mysql2'
  gem 'activerecord-mysql2-adapter'
end
