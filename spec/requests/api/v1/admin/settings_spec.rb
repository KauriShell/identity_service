# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin settings API", type: :request do
  let(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  describe "GET /api/v1/admin/settings/jobs" do
    it "returns scheduled job metadata" do
      get "/api/v1/admin/settings/jobs", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to be_an(Array)
      expect(json_body["data"].first["service"]).to eq("identity_service")
    end
  end

  describe "GET /api/v1/admin/settings/kyc-tiers" do
    it "returns configured kyc tiers" do
      get "/api/v1/admin/settings/kyc-tiers", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to be_an(Array)
    end
  end
end
