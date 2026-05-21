# frozen_string_literal: true

class KycVerificationSerializer < ApplicationSerializer
  set_type :kycVerification

  attributes :document_type, :status, :user_id

  attribute :reviewed_at do |verification|
    verification.reviewed_at&.iso8601
  end

  attribute :created_at do |verification|
    verification.created_at&.iso8601
  end

  attribute :updated_at do |verification|
    verification.updated_at&.iso8601
  end
end
