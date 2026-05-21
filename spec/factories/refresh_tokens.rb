# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    user
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    expires_at { 30.days.from_now }
  end
end
