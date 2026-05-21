# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceTenant, type: :model do
  subject { build(:service_tenant) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:token_digest) }
end
