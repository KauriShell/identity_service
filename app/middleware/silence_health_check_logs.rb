# frozen_string_literal: true

# Skips request-line / processing logs for cheap health probes (e.g. Docker
# healthcheck every 5s) so logs stay readable.
class SilenceHealthCheckLogs
  PATHS = ["/api/v1/health", "/api/v1/health/"].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    if PATHS.include?(env["PATH_INFO"].to_s)
      Rails.logger.silence { @app.call(env) }
    else
      @app.call(env)
    end
  end
end
