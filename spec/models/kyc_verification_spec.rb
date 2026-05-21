# frozen_string_literal: true

require "rails_helper"

RSpec.describe KycVerification, type: :model do
  subject { build(:kyc_verification) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:document_type) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to define_enum_for(:document_type).with_values(national_id: 0, passport: 1, drivers_license: 2).with_prefix(:document) }
  it { is_expected.to define_enum_for(:status).with_values(pending: 0, submitted: 1, under_review: 2, approved: 3, rejected: 4).with_prefix(:status) }
end
