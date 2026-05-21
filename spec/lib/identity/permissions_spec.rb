# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::Permissions do
  describe ".for" do
    it "returns mediator permissions with boolean flags" do
      user = build(:user, role: :mediator)
      perms = described_class.for(user)

      expect(perms.dig("disputes", "resolve")).to be(true)
      expect(perms.dig("disputes", "assign")).to be(false)
      expect(perms.dig("mediator", "view_dashboard")).to be(true)
    end

    it "returns admin dispute and mediator management permissions" do
      user = build(:user, role: :admin)
      perms = described_class.for(user)

      expect(perms["disputes"]).to include("view_all", "assign", "reassign")
      expect(perms["mediators"]).to include("manage")
    end

    it "returns empty hash for members" do
      user = build(:user, role: :member)
      expect(described_class.for(user)).to eq({})
    end
  end
end
