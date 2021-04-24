source 'https://rubygems.org'

# ruby '2.4.1'

# gem 'rails', '4.2.10'
# gem 'rails', '6.0.3.4'
# gem 'railties', '6.0.3.4'
# gem 'activesupport', '6.0.3.4'
# gem 'rails', '6.1.3'
# gem 'railties', '6.1.3'
# gem 'activesupport', '6.1.3'

gem 'rails', '~> 6.1'
gem 'railties', '~> 6.1'
gem 'activesupport', '~> 6.1'

# gem 'pg', '~> 0.15'
gem 'pg', '~> 1.2'

gem 'calendar_date_select'

# gem 'chamber', '~> 2.8.0'
gem 'chamber', '~> 2.14'

# gem 'coffee-rails', '~> 4.1.0'
gem 'coffee-rails', '~> 5.0'

gem 'decent_exposure'
gem 'devise'

# gem 'jbuilder', '~> 2.0'
gem 'jbuilder', '~> 2.10'

gem 'jqgrid-jquery-rails', '~> 4.6'
gem 'jquery-rails', '~> 4.4'
gem 'jquery-ui-rails', '~> 6.0'
gem 'rails-ujs', '0.1.0'

# gem 'sass-rails', '~> 5.0'
# gem 'sass-rails', '~> 6.0'
gem 'sassc-rails', '~> 2.1'

# gem 'uglifier', '>= 1.3.0'
gem 'uglifier', '~> 4.2'

gem 'will_paginate'
gem 'whenever'



gem 'asigbiophys', path: 'vendor/asigbiophys'

#group :staging, :production do
#  gem 'rails_12factor'
#end

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-ext'
  # gem 'capistrano-passenger'
  gem 'capistrano-rails'
  # gem 'capistrano-rbenv', github: 'capistrano/rbenv'
  gem 'capistrano-rbenv'
  # gem 'mysqltopostgres', github: 'maxlapshin/mysql2postgres'
  gem 'web-console'
end

group :development, :staging do
  gem 'mail_safe'
end

group :development, :test do
  gem 'byebug'
  # gem 'factory_girl_rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'valid_attribute'
  gem 'guard-rspec'
end

group :test do
  gem 'simplecov', require: false
end
