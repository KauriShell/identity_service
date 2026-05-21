# frozen_string_literal: true

# Secondary check using Marcel on file bytes (not only the client-declared content type).
# Runs async so sign-up spikes enqueue work instead of blocking request threads.
class VerifyKycDocumentsJob < ApplicationJob
  queue_as :kyc

  discard_on ActiveRecord::RecordNotFound

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(verification_id)
    verification = KycVerification.find_by(id: verification_id)
    return unless verification

    verification.documents.attachments.to_a.each do |attachment|
      attachment.blob.open do |io|
        detected = Marcel::MimeType.for(io)
        attachment.purge unless KycVerification::ALLOWED_CONTENT_TYPES.include?(detected)
      end
    end

    verification.reload
    return if verification.documents.attached?

    verification.update!(
      status: :rejected,
      notes: "Automated validation failed: document content did not match allowed types."
    )
    verification.user.update!(kyc_status: :pending)
  end
end
