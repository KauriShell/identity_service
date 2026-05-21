# frozen_string_literal: true

class AppRedis
  def self.connection
    @connection ||= Redis.new(url: ENV.fetch("REDIS_URL"))
  end
end
