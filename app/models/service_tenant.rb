# frozen_string_literal: true

class ServiceTenant < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  after_commit :invalidate_api_caches

  def self.hash_token(raw_token)
    Digest::SHA256.hexdigest("#{ENV.fetch("SERVICE_TOKEN_SALT")}--#{raw_token}")
  end

  def self.generate_token
    SecureRandom.hex(32)
  end

  def rotate_token!
    raw_token = self.class.generate_token
    update!(token_digest: self.class.hash_token(raw_token))
    raw_token
  end

  private

  def invalidate_api_caches
    IdentityService::ApiCache.invalidate("service_tenants_index")
    IdentityService::ApiCache.invalidate("service_tenants_show")
  end
end
