# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "#jwt_payload" do
    it "includes permissions for mediators" do
      user = build(:mediator)
      payload = user.jwt_payload

      expect(payload[:permissions].dig("disputes", "resolve")).to be(true)
      expect(payload[:role]).to eq("mediator")
    end

    it "includes dispute management permissions for admins" do
      user = build(:admin)
      payload = user.jwt_payload

      expect(payload[:permissions]["disputes"]).to include("assign", "reassign", "view_all")
      expect(payload[:permissions]["mediators"]).to include("manage")
    end
  end
end
