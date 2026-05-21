# frozen_string_literal: true

FactoryBot.define do
  factory :kyc_verification do
    user
    document_type { :passport }
    status { :pending }
  end
end
