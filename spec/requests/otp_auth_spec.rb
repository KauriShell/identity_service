# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OTP Auth", type: :request do
  describe "POST /api/v1/auth/send_otp" do
    it "sends an otp for a valid kenya phone" do
      post "/api/v1/auth/send_otp", params: { phone: "0712345678" }, as: :json

      expect(response).to have_http_status(:accepted)
      expect(json_body.dig("data", "expires_in_seconds")).to eq(300)
      expect(json_body.dig("data", "resend_after_seconds")).to eq(60)
      expect(json_body.dig("meta", "debug_otp")).to be_present
    end

    it "rejects invalid phone" do
      post "/api/v1/auth/send_otp", params: { phone: "123" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("errors", 0, "source")).to eq("invalid_phone")
    end
  end

  describe "POST /api/v1/auth/verify_otp" do
    it "verifies otp and returns auth tokens" do
      post "/api/v1/auth/send_otp", params: { phone: "0712345678" }, as: :json
      code = json_body.dig("meta", "debug_otp")

      post "/api/v1/auth/verify_otp", params: { phone: "0712345678", otp_code: code }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("meta", "accessToken")).to be_present
      expect(json_body.dig("meta", "refreshToken")).to be_present
      expect(json_body.dig("data", "id")).to be_present
    end

    it "rejects invalid otp code" do
      post "/api/v1/auth/send_otp", params: { phone: "0712345678" }, as: :json

      post "/api/v1/auth/verify_otp", params: { phone: "0712345678", otp_code: "000000" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_body.dig("errors", 0, "source")).to eq("invalid_otp")
    end
  end
end
