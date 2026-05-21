# frozen_string_literal: true

module JwtDenylist
  extend ActiveSupport::Concern
  include Devise::JWT::RevocationStrategies::JTIMatcher

  DENYLIST_PREFIX = "jwt_denylist"

  class_methods do
    def revoke_jwt(payload, user)
      super
      jti = payload["jti"]
      exp = payload["exp"].to_i
      ttl = exp - Time.current.to_i
      return if ttl <= 0

      AppRedis.connection.setex(redis_key(jti), ttl, 1)
    end

    def jwt_revoked?(payload, user)
      super || AppRedis.connection.exists?(redis_key(payload["jti"]))
    end

    def redis_key(jti)
      "#{DENYLIST_PREFIX}:#{jti}"
    end
  end
end
