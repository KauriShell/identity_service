# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceTenantPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:admin) { build(:admin) }
  let(:superadmin) { build(:superadmin) }
  let(:tenant) { build(:service_tenant) }

  permissions :index?, :show?, :create?, :update?, :destroy? do
    it { is_expected.not_to permit(admin, tenant) }
    it { is_expected.to permit(superadmin, tenant) }
  end
end
