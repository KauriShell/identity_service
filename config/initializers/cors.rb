# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

allowed_origins = ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
if Rails.env.production? && allowed_origins.empty?
  raise "ALLOWED_ORIGINS must list at least one browser origin in production (comma-separated)."
end

# Local/dev convenience when unset (production is guarded above).
allowed_origins = %w[http://localhost:3000 http://localhost:3001] if allowed_origins.empty?

# Browser clients (e.g. Expo Web / Metro) call the API from a different origin than the Next app.
expo_web_dev_origins = %w[
  http://localhost:8081
  http://127.0.0.1:8081
  http://localhost:19006
  http://127.0.0.1:19006
]
allowed_origins = (allowed_origins + expo_web_dev_origins).uniq if Rails.env.development?

origin_allowlist = allowed_origins.dup
# Expo Web opened as http://192.168.x.x:8081 from another machine on the LAN.
origin_allowlist << /\Ahttp:\/\/192\.168\.\d{1,3}\.\d{1,3}(:\d+)?\z/ if Rails.env.development?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*origin_allowlist)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: ["Authorization"],
             max_age: 7200
  end
end
