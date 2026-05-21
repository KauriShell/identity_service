# frozen_string_literal: true

class KycVerification < ApplicationRecord
  has_paper_trail only: [:status]

  belongs_to :user
  belongs_to :reviewer, class_name: "User", optional: true

  has_many_attached :documents

  enum :document_type, { national_id: 0, passport: 1, drivers_license: 2 }, prefix: :document
  enum :status, { pending: 0, submitted: 1, under_review: 2, approved: 3, rejected: 4 }, prefix: :status

  validates :document_type, presence: true
  validates :status, presence: true
  validate :documents_are_valid
  after_commit :invalidate_api_caches

  MAX_DOCUMENT_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png application/pdf].freeze

  private

  def documents_are_valid
    return unless documents.attached?

    documents.each do |document|
      unless ALLOWED_CONTENT_TYPES.include?(document.blob.content_type)
        errors.add(:documents, "must be a JPG, PNG, or PDF")
      end
      if document.blob.byte_size > MAX_DOCUMENT_SIZE
        errors.add(:documents, "must be smaller than 10MB")
      end
    end
  end

  def invalidate_api_caches
    IdentityService::ApiCache.invalidate("kyc_status")
    IdentityService::ApiCache.invalidate("kyc_index")
    IdentityService::ApiCache.invalidate("users_show")
    IdentityService::ApiCache.invalidate("users_index")
  end
end
