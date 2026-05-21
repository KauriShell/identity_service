# frozen_string_literal: true

class Rack::Attack
  self.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL"))

  class << self
    def metrics_redis
      AppRedis.connection
    end

    def observe_attack!(request:, result:)
      matched = request.env["rack.attack.matched"].to_s.presence || "unknown"
      discriminator = request.env["rack.attack.match_discriminator"].to_s.presence || "none"
      key = [
        "observability",
        "rack_attack",
        result,
        request.request_method.downcase,
        matched,
        discriminator
      ].join(":")

      metrics_redis.incr(key)
      metrics_redis.expire(key, 7.days.to_i)
    rescue StandardError
      nil
    end
  end

  throttle("logins/ip", limit: 5, period: 20) do |req|
    req.ip if req.path == "/api/v1/auth/sign_in" && req.post?
  end

  throttle("registrations/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/sign_up" && req.post?
  end

  throttle("password_reset/email", limit: 10, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/password" && req.post?
      req.params.dig("user", "email")&.downcase
    end
  end

  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  throttle("refresh/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/refresh" && req.post?
  end

  throttle("otp_send/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/send_otp" && req.post?
  end

  throttle("otp_send/phone", limit: 5, period: 10.minutes) do |req|
    if req.path == "/api/v1/auth/send_otp" && req.post?
      phone = req.params["phone"].to_s.gsub(/\D/, "")
      phone.presence
    end
  end

  throttle("otp_verify/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/verify_otp" && req.post?
  end

  throttle("otp_verify/phone", limit: 15, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/verify_otp" && req.post?
      phone = req.params["phone"].to_s.gsub(/\D/, "")
      phone.presence
    end
  end

  blocklist("blocklisted-ips") do |req|
    AppRedis.connection.sismember("blocklisted_ips", req.ip)
  end

  self.throttled_responder = lambda do |request|
    Rack::Attack.observe_attack!(request: request, result: "throttled")
    body = {
      errors: [
        {
          status: "429",
          title: "Too Many Requests",
          detail: "Rate limit exceeded."
        }
      ]
    }
    [429, { "Content-Type" => "application/json" }, [body.to_json]]
  end
end
