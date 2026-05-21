# frozen_string_literal: true

require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  subject { build(:refresh_token) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:token_digest) }
  it { is_expected.to validate_presence_of(:expires_at) }
end
