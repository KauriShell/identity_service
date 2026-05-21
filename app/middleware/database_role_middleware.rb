# frozen_string_literal: true

class DatabaseRoleMiddleware
  POST_WRITE_STICKY_SECONDS = 5
  WROTE_RECENTLY_HEADER = "X-TB-Wrote-Recently"

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    role = should_use_primary?(request) ? :writing : :reading
    ApplicationRecord.connected_to(role: role) do
      status, headers, body = @app.call(env)
      [status, add_write_header(headers, request), body]
    end
  end

  private

  def should_use_primary?(request)
    return true if ENV.fetch("FORCE_PRIMARY_READS", "false") == "true"
    return true if write_method?(request)
    return true if wrote_recently?(request)
    return true if primary_read_get?(request)

    false
  end

  def primary_read_get?(request)
    request.get? && request.path.start_with?("/api/v1/auth/unlock")
  end

  def write_method?(request)
    %w[POST PATCH PUT DELETE].include?(request.request_method)
  end

  def wrote_recently?(request)
    wrote_at = request.cookies["tb_wrote_at"] || request.get_header("HTTP_#{WROTE_RECENTLY_HEADER.upcase.tr('-', '_')}")
    return false if wrote_at.blank?

    Time.at(wrote_at.to_i) > POST_WRITE_STICKY_SECONDS.seconds.ago
  rescue StandardError
    false
  end

  def add_write_header(headers, request)
    return headers unless write_method?(request)

    headers["Set-Cookie"] = "tb_wrote_at=#{Time.current.to_i}; Path=/; HttpOnly; SameSite=Strict; Max-Age=#{POST_WRITE_STICKY_SECONDS}"
    headers[WROTE_RECENTLY_HEADER] = Time.current.to_i.to_s
    headers
  end
end
