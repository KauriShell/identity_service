require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Allow requests routed via Docker service name (e.g. app:3000).
  config.hosts << "app"
  config.hosts << /\Aapp(?::\d+)?\z/
  config.hosts << "identity"
  config.hosts << /\Aidentity(?::\d+)?\z/
  config.hosts << "identity_service"
  config.hosts << /\Aidentity_service(?::\d+)?\z/
  # Mobile dev: host machine via published Docker ports (Android emulator uses 10.0.2.2).
  config.hosts << "localhost"
  config.hosts << "127.0.0.1"
  config.hosts << "10.0.2.2"
  config.hosts << /\A10\.0\.2\.2(?::\d+)?\z/
  # Physical device on same Wi‑Fi hitting Docker published ports (e.g. http://192.168.1.10:3000).
  config.hosts << /\A192\.168\.\d{1,3}\.\d{1,3}(?::\d+)?\z/

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Use Mailpit in development (SMTP on 1025, UI on 8025).
  # If you run without Docker, set MAILPIT_HOST to your SMTP host.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("MAILPIT_HOST", "mailpit"),
    port: ENV.fetch("MAILPIT_PORT", "1025").to_i,
    domain: ENV.fetch("MAILPIT_DOMAIN", "mailpit"),
    enable_starttls_auto: false
  }

  if ENV["MAILPIT_USER"].present?
    config.action_mailer.smtp_settings[:authentication] = :plain
    config.action_mailer.smtp_settings[:user_name] = ENV["MAILPIT_USER"]
    config.action_mailer.smtp_settings[:password] = ENV["MAILPIT_PASS"]
  end

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.action_mailer.default_url_options = {
    host: ENV.fetch("DEFAULT_URL_HOST", "localhost"),
    port: ENV.fetch("DEFAULT_URL_PORT", 3000)
  }

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Default: async (no worker process). Set USE_SOLID_QUEUE=1 with `bin/jobs` (e.g. docker-compose) to mirror production.
  config.active_job.queue_adapter = ENV["USE_SOLID_QUEUE"].present? ? :solid_queue : :async

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
end
