# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model
  include JwtDenylist

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :confirmable,
         :lockable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: User

  enum :role, { member: 0, admin: 1, superadmin: 2, mediator: 3 }, prefix: :role
  enum :kyc_status, { pending: 0, submitted: 1, under_review: 2, approved: 3, rejected: 4 }, prefix: :kyc
  enum :status, { active: 0, suspended: 1, deactivated: 2 }, prefix: :status

  has_many :refresh_tokens, dependent: :destroy
  has_many :kyc_verifications, dependent: :destroy
  has_many :reviewed_kyc_verifications, class_name: "KycVerification", foreign_key: :reviewer_id, inverse_of: :reviewer
  has_many :notifications, dependent: :destroy
  has_many :payout_accounts, dependent: :destroy
  has_many :devices, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :jti, presence: true
  validate :email_not_reserved_for_member

  before_validation :ensure_jti, on: :create
  after_discard :revoke_tokens!
  after_commit :invalidate_api_caches

  RESERVED_EMAIL_PREFIXES = %w[
    admin
    root
    superadmin
    support
    security
    sysadmin
    moderator
    staff
    operator
    service
  ].freeze

  def jwt_payload
    super.merge(
      user_id: id,
      role: role,
      kyc_status: kyc_status,
      permissions: Identity::Permissions.for(self)
    )
  end

  def revoke_tokens!
    TokenRevocationService.revoke_all_refresh_tokens!(self)
    update!(jti: SecureRandom.uuid)
  end

  private

  def email_not_reserved_for_member
    return if email.blank?
    return unless role_member?

    local_part = email.to_s.split("@").first.to_s.downcase
    reserved = RESERVED_EMAIL_PREFIXES.find { |prefix| local_part.start_with?(prefix) }
    return unless reserved

    errors.add(:email, "prefix is reserved for internal accounts")
  end

  def ensure_jti
    self.jti ||= SecureRandom.uuid
  end

  def invalidate_api_caches
    IdentityService::ApiCache.invalidate("users_index")
    IdentityService::ApiCache.invalidate("users_show")
    IdentityService::ApiCache.invalidate("kyc_status")
    IdentityService::ApiCache.invalidate("kyc_index")
    IdentityService::ApiCache.invalidate("service_tenants_index")
    IdentityService::ApiCache.invalidate("service_tenants_show")
    IdentityService::ApiCache.invalidate("notifications_index")
    IdentityService::ApiCache.invalidate("payout_accounts_index")
  end
end
