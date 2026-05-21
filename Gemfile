source "https://rubygems.org"

ruby "3.3.7"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

gem "redis", "~> 5.2"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

gem "bcrypt", "~> 3.1.7"

gem "devise", ">= 5.0.3", "< 6"
gem "devise-jwt", "~> 0.11"
gem "discard", "~> 1.2"
gem "jsonapi-serializer", "~> 2.2"
gem "pundit", "~> 2.3"
gem "rack-attack", "~> 6.7"
gem "rack-cors", "~> 2.0"
gem "aws-sdk-s3", "~> 1.169"
gem "paper_trail", "~> 16.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  gem "simplecov", require: false
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "shoulda-matchers", "~> 5.3"
  gem "faker", "~> 3.3"
  gem "database_cleaner-active_record", "~> 2.2"
  gem "rswag-api", "~> 2.16"
  gem "rswag-ui", "~> 2.16"
  gem "rswag-specs", "~> 2.16"
  gem "mission_control-jobs"
  # Needed for API-only apps to serve Mission Control assets.
  gem "propshaft"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

gem "solid_queue", "~> 1.4"
