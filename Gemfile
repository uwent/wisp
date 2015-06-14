source 'http://rubygems.org'

gem 'rails', '3.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'activerecord-mysql2-adapter' # think this is because of the explicit connects in awon_controller
# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano', '~> 2.15'

# Install this gem, do "rails g jquery:install", then javascript_include_tag :defaults for any page needing it
# (which includes confirmation dialogs on button_to)
gem 'jquery-rails'

# Omniauth Google authentication with Devise
gem 'devise'
gem 'omniauth'
gem 'omniauth-google-oauth2'

gem 'asigbiophys', :path => "vendor/asigbiophys"

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  # For dev use, gets around the RequestURITooLarge error with WEBrick and OpenID
  gem 'mongrel', '1.2.0.pre2'
  gem 'sqlite3'
  # Per http://stackoverflow.com/questions/10918019/gem-issue-database-rake-aborted:
  # gem 'debugger'
end

group :test do
  gem 'simplecov', require: false
end

group :production do
  gem 'mysql2'
  # Later versions of the Mysql2 gem do not include the AR adapter, so pull that in too
  gem 'activerecord-mysql2-adapter'
end
