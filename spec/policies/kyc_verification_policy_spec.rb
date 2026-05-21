# frozen_string_literal: true

require "rails_helper"

RSpec.describe KycVerificationPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:member) { build(:user) }
  let(:admin) { build(:admin) }
  let(:verification) { build(:kyc_verification, user: member) }

  permissions :submit?, :status? do
    it { is_expected.to permit(member, KycVerification) }
  end

  permissions :index?, :review? do
    it { is_expected.not_to permit(member, verification) }
    it { is_expected.to permit(admin, verification) }
  end
end
