# frozen_string_literal: true

class RefreshTokenIssuer
  Result = Struct.new(:token, :expires_at)
  def self.call(user)
    active_tokens = user.refresh_tokens.active.order(expires_at: :asc)
    max_active = Rails.configuration.x.refresh_token_max_active
    excess = active_tokens.count - max_active + 1
    if excess.positive?
      ids = active_tokens.limit(excess).pluck(:id)
      user.refresh_tokens.where(id: ids).update_all(revoked_at: Time.current)
    end

    raw_token = SecureRandom.hex(64)
    expires_at = Rails.configuration.x.refresh_token_ttl.from_now
    digest = Digest::SHA256.hexdigest(raw_token)

    user.refresh_tokens.create!(token_digest: digest, expires_at: expires_at)

    Result.new(raw_token, expires_at)
  end
end
