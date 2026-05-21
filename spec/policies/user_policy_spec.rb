# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:member) { build(:user) }
  let(:admin) { build(:admin) }
  let(:superadmin) { build(:superadmin) }
  let(:other_user) { build(:user) }

  permissions :index? do
    it { is_expected.not_to permit(member, User) }
    it { is_expected.to permit(admin, User) }
  end

  permissions :show?, :update? do
    it { is_expected.to permit(member, member) }
    it { is_expected.not_to permit(member, other_user) }
    it { is_expected.to permit(admin, other_user) }
  end

  permissions :destroy? do
    it { is_expected.not_to permit(member, other_user) }
    it { is_expected.to permit(admin, other_user) }
  end

  permissions :update? do
    it { is_expected.to permit(superadmin, other_user) }
  end
end
