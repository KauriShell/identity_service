# frozen_string_literal: true

class OtpCode < ApplicationRecord
  CODE_TTL = 5.minutes
  RESEND_COOLDOWN = 60.seconds
  MAX_ATTEMPTS = 5

  validates :phone_number, presence: true
  validates :code_digest, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def consumed?
    consumed_at.present?
  end

  def over_attempt_limit?
    attempts_count >= MAX_ATTEMPTS
  end
end
