# frozen_string_literal: true

class TokenRevocationService
  def self.revoke_refresh_token!(refresh_token)
    refresh_token.revoke!
  end

  def self.revoke_all_refresh_tokens!(user)
    user.refresh_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
  end
end
