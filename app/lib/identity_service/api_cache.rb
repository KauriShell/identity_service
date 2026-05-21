# frozen_string_literal: true

require "digest"
require "json"

module IdentityService
  module ApiCache
    module_function

    VERSION_TTL = 30.days
    METRICS_TTL = 30.days

    def fetch(resource:, parts:, expires_in: 30.seconds, race_condition_ttl: 5.seconds)
      key = cache_key(resource: resource, parts: parts)
      cached = Rails.cache.read(key)
      if cached
        increment_metric(resource, :hit)
        log_observation(resource: resource, event: "cache_hit", key: key)
        return cached
      end

      increment_metric(resource, :miss)
      log_observation(resource: resource, event: "cache_miss", key: key)
      value = yield
      Rails.cache.write(key, value, expires_in: expires_in, race_condition_ttl: race_condition_ttl)
      value
    end

    def invalidate(resource)
      version = Time.current.to_f
      Rails.cache.write(version_key(resource), version, expires_in: VERSION_TTL)
      increment_metric(resource, :invalidate)
      log_observation(resource: resource, event: "cache_invalidate", version: version)
      version
    end

    def current_version(resource)
      Rails.cache.fetch(version_key(resource), expires_in: VERSION_TTL) { 1 }
    end

    def cache_key(resource:, parts:)
      raw = JSON.generate(parts.to_h.deep_stringify_keys.sort.to_h)
      digest = Digest::SHA256.hexdigest(raw)
      "identity_service:api_cache:#{resource}:v#{current_version(resource)}:#{digest}"
    end

    def version_key(resource)
      "identity_service:api_cache:#{resource}:version"
    end

    def metric_key(resource, metric)
      "identity_service:api_cache:metrics:#{resource}:#{metric}"
    end

    def increment_metric(resource, metric)
      key = metric_key(resource, metric)
      incremented = Rails.cache.increment(key, 1, expires_in: METRICS_TTL)
      return incremented if incremented

      current = Rails.cache.read(key).to_i
      Rails.cache.write(key, current + 1, expires_in: METRICS_TTL)
      current + 1
    rescue StandardError
      nil
    end

    def log_observation(resource:, event:, key: nil, version: nil)
      Rails.logger.info(
        {
          message: event,
          service: "identity_service",
          component: "api_cache",
          resource: resource,
          cache_key: key,
          version: version,
          at: Time.current.iso8601
        }.compact.to_json
      )
    rescue StandardError
      nil
    end
  end
end
