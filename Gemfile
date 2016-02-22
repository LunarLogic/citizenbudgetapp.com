source 'https://rubygems.org'
ruby '2.3.0'

gem 'rails', '4.2.5.1'
gem 'actionpack-action_caching'
gem 'rails-i18n'
gem 'dotenv-rails'

# Server
gem 'unicorn'

# Database
gem 'pg'
gem 'paranoia', '~> 2.0'

# Admin
gem 'activeadmin', '1.0.0.pre2'

gem 'cancan'
gem 'devise'
gem 'devise-i18n'
gem 'google-api-client', '0.9'
gem 'jwt'
gem 'mustache'

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

# Heroku API
gem 'oj'
gem 'multi_json'
gem 'faraday'

# Rake
gem 'ruby-progressbar'

# Middleware
gem 'rack-timeout'    # Abort requests that are taking too long
gem 'rack-revision'   # Adds a revision number to the request's header
gem 'rack-protection' # Protects against typical web attacks
gem 'rack-attack'     # Handles blocking & throttling

# Reporting
gem "skylight"
gem 'sentry-raven'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # Non-Heroku deployments
  unless ENV['HEROKU']
    gem 'therubyracer', require: 'v8'
    gem 'libv8', '3.16.14.7'
  end

  gem 'sass-rails', '~> 5.0'
  gem 'coffee-rails', '~> 4.1.0'
  gem 'uglifier', '>= 1.3.0'
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

  # Performance
  gem 'action_dispatch-gz_static'
  gem 'memcachier'
  gem 'dalli'
end
