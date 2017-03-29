source 'https://rubygems.org'
ruby '2.3.0'

gem 'rails', '4.2.8'
gem 'actionpack-action_caching'
gem 'rails-i18n'
gem 'dotenv-rails'

gem 'cancan'
gem 'devise'
gem 'google-api-client', '~> 0.6.4', require: 'google/api_client'
gem 'jwt', '~> 0.1.4' # google-api-client
gem 'mustache'

# Server
gem 'puma'

# Database
gem 'pg'
gem 'paranoia', '~> 2.0'

# Admin
gem 'activeadmin', '1.0.0.pre5'

# I18n
gem 'devise-i18n'
gem 'i18n-timezones'

# Image uploads
gem 'fog'
gem 'mini_magick'
gem 'carrierwave'

# Views
gem 'rdiscount'
gem 'unicode_utils'
gem 'bourgeois'

# Export
gem 'spreadsheet'
gem 'axlsx', '2.1.0.pre'
gem 'rubyzip', '>= 1.0.0'

# Rake
gem 'ruby-progressbar'

# Middleware
group :production do
  gem 'rack-timeout'    # Abort requests that are taking too long
  gem 'rack-revision'   # Adds a revision number to the request's header
  gem 'rack-protection' # Protects against typical web attacks
  gem 'rack-attack'     # Handles blocking & throttling
end

# Reporting
gem 'skylight'
gem 'sentry-raven'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
  gem 'coffee-rails', '~> 4.1.0'
  gem 'coffee-script'
end

group :development, :test do
  gem 'foreman'

  gem 'pry-rails'
  gem 'byebug'

  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'ffaker'

  gem 'brakeman', require: false
  gem 'dawnscanner', require: false
end

group :development do
  gem 'mechanize'
  gem 'odf-report'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  gem 'database_cleaner'
  gem 'shoulda-matchers', '~> 3.1'
end

group :production do
  gem 'rails_12factor'
  gem 'lograge'
end

group :migrate do
  # TODO remove after successful migration from Mongo to Postgresql
  gem 'mongoid'
  gem 'redis'
  gem 'bulk_insert'
end
