# frozen_string_literal: true

FactoryBot.define do
  factory :service_tenant do
    name { Faker::Company.unique.name }
    description { Faker::Company.catch_phrase }
    active { true }
    token_digest { ServiceTenant.hash_token(SecureRandom.hex(16)) }
  end
end
