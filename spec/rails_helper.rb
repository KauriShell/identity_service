# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['DATABASE_URL_TEST'] ||= 'postgresql://localhost/identity_service_test'
ENV['DATABASE_URL'] = ENV['DATABASE_URL_TEST']
ENV['DEVISE_JWT_SECRET_KEY'] ||= 'test-secret'
ENV['DEVISE_PEPPER'] ||= 'test-pepper'
ENV['REDIS_URL'] ||= 'redis://localhost:6379/1'
ENV['SERVICE_TOKEN_SALT'] ||= 'test-salt'
%w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_BUCKET AWS_KMS_KEY_ID].each do |key|
  ENV[key] ||= "test"
end
ENV['RAILS_ENV'] = 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'database_cleaner/active_record'
# Hostnames like `db` (Docker Compose) are treated as "remote"; test DB truncation
# is still gated by RAILS_ENV=test.
DatabaseCleaner.allow_remote_database_url = true if Rails.env.test?
if defined?(DatabaseCleaner::Safeguard) && DatabaseCleaner::Safeguard.respond_to?(:allow_remote_database_url=)
  DatabaseCleaner::Safeguard.allow_remote_database_url = true
end
require 'pundit/rspec'
require 'rswag/specs'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include FactoryBot::Syntax::Methods
  config.include AuthHelpers, type: :request
  config.include JsonapiHelpers, type: :request
  config.include JsonapiHelpers, type: :controller
  config.include ActionDispatch::TestProcess, type: :request

  config.before(:suite) do
    begin
      DatabaseCleaner.clean_with(:truncation)
    rescue DatabaseCleaner::Safeguard::Error
      # Some containerized test setups expose DATABASE_URL as "remote" (e.g. host=db).
      # Per-example transaction cleaning still runs below.
      nil
    end
  end

  config.around(:each) do |example|
    strategy = case example.metadata[:type]
               when :request, :system, :feature
                 :truncation
               else
                 :transaction
               end

    DatabaseCleaner.strategy = strategy
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
