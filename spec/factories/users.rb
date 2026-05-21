# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "Password1234!" }
    jti { SecureRandom.uuid }
    role { :member }
    kyc_status { :pending }
    status { :active }
    confirmed_at { Time.current }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { Faker::PhoneNumber.phone_number }
    metadata { { "signupSource" => "spec" } }
  end

  factory :admin, parent: :user do
    role { :admin }
  end

  factory :superadmin, parent: :user do
    role { :superadmin }
  end

  factory :mediator, parent: :user do
    role { :mediator }
  end
end
