# frozen_string_literal: true

class PayoutAccount < ApplicationRecord
  belongs_to :user

  ACCOUNT_TYPES = %w[mpesa bank].freeze

  validates :account_type, inclusion: { in: ACCOUNT_TYPES }
  validates :phone_number, presence: true, if: -> { account_type == "mpesa" }
  validates :bank_code, :account_number, presence: true, if: -> { account_type == "bank" }

  before_save :ensure_single_primary, if: -> { primary? && will_save_change_to_primary? }

  private

  def ensure_single_primary
    user.payout_accounts.where.not(id: id).update_all(primary: false)
  end
end
