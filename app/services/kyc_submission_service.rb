# frozen_string_literal: true

class KycSubmissionService
  def self.call(user:, document_type:, documents:)
    if user.kyc_status.in?(%w[submitted under_review approved])
      user.errors.add(:base, "KYC is already in progress or approved.")
      raise ActiveRecord::RecordInvalid, user
    end

    if documents.blank?
      user.errors.add(:base, "KYC documents are required.")
      raise ActiveRecord::RecordInvalid, user
    end

    unless KycVerification.document_types.key?(document_type.to_s)
      user.errors.add(:base, "Document type is not supported.")
      raise ActiveRecord::RecordInvalid, user
    end

    verification = ActiveRecord::Base.transaction do
      verification = user.kyc_verifications.create!(
        document_type: document_type,
        status: :submitted
      )

      Array(documents).each do |document|
        verification.documents.attach(document)
      end

      verification.save!
      user.update!(kyc_status: :submitted)
      verification
    end

    VerifyKycDocumentsJob.perform_later(verification.id)
    verification
  end
end
