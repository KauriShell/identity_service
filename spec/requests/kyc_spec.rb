# frozen_string_literal: true

require "rails_helper"

RSpec.describe "KYC", type: :request do
  describe "submit" do
    it "submits a kyc verification" do
      user = create(:user)
      document = fixture_file_upload("kyc.pdf", "application/pdf")
      params = { kyc: { document_type: "passport", documents: [document] } }

      headers = auth_headers(user).except("Content-Type")
      post "/api/v1/kyc/submit", params: params, headers: headers

      expect(response).to have_http_status(:created)
      expect(user.reload.kyc_status).to eq("submitted")
    end

    it "rejects unsupported document types" do
      user = create(:user)
      document = fixture_file_upload("kyc.pdf", "application/pdf")
      params = { kyc: { document_type: "visa", documents: [document] } }

      headers = auth_headers(user).except("Content-Type")
      post "/api/v1/kyc/submit", params: params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("errors", 0, "detail")).to match(/document type|not supported/i)
    end

    it "rejects documents with disallowed content types" do
      user = create(:user)
      bad = Tempfile.new(["fake", ".txt"])
      bad.write("not a real image")
      bad.rewind
      uploaded = fixture_file_upload(bad.path, "text/plain")
      params = { kyc: { document_type: "passport", documents: [uploaded] } }

      headers = auth_headers(user).except("Content-Type")
      post "/api/v1/kyc/submit", params: params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects duplicate submission when KYC is already in progress" do
      user = create(:user, kyc_status: :submitted)
      document = fixture_file_upload("kyc.pdf", "application/pdf")
      params = { kyc: { document_type: "passport", documents: [document] } }

      headers = auth_headers(user).except("Content-Type")
      post "/api/v1/kyc/submit", params: params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("errors", 0, "detail")).to match(/already in progress|approved/i)
    end
  end

  describe "status" do
    it "returns current status" do
      user = create(:user, kyc_status: :pending)

      get "/api/v1/kyc/status", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("data", "attributes", "kycStatus")).to eq("pending")
    end

    it "does not expose reviewer notes to members" do
      user = create(:user, kyc_status: :pending)

      get "/api/v1/kyc/status", headers: auth_headers(user)

      expect(json_body.to_json).not_to include("notes")
    end
  end

  describe "serialization" do
    it "omits notes from the member-facing serializer" do
      verification = build(:kyc_verification, notes: "internal note")
      attrs = KycVerificationSerializer.new(verification).serializable_hash[:data][:attributes]

      expect(attrs).not_to have_key(:notes)
    end
  end

  describe "admin index" do
    it "returns pagination metadata" do
      admin = create(:admin)
      users = create_list(:user, 3)
      users.each do |u|
        create(:kyc_verification, user: u, status: :submitted, document_type: :passport)
      end

      get "/api/v1/kyc", params: { page: 1, size: 2 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["meta"]).to include(
        "page" => 1,
        "size" => 2,
        "total" => 3
      )
      expect(json_body["data"].length).to eq(2)
    end

    it "caps page size at 100" do
      admin = create(:admin)

      get "/api/v1/kyc", params: { page: 1, size: 500 }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["meta"]["size"]).to eq(100)
    end
  end

  describe "admin review" do
    it "updates status" do
      admin = create(:admin)
      verification = create(:kyc_verification, status: :submitted)
      params = { kyc: { status: "approved", notes: "ok" } }

      patch "/api/v1/kyc/#{verification.id}/review", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(verification.reload.status).to eq("approved")
      expect(verification.user.reload.kyc_status).to eq("approved")
      expect(json_body.dig("data", "attributes", "notes")).to eq("ok")
    end
  end
end
