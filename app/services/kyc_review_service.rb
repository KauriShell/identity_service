# frozen_string_literal: true

class KycReviewService
  def self.call(verification:, reviewer:, status:, notes: nil)
    verification.update!(
      status: status,
      notes: notes,
      reviewer: reviewer,
      reviewed_at: Time.current
    )
    verification.user.update!(kyc_status: status)
    verification
  end
end
