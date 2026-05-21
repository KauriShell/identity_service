# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Payout Accounts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "CRUD endpoints" do
    it "creates, lists, updates, sets primary and deletes payout accounts" do
      post "/api/v1/payout_accounts",
           params: {
             payout_account: {
               account_type: "mpesa",
               phone_number: "254712345678"
             }
           },
           headers: headers,
           as: :json
      expect(response).to have_http_status(:created)
      first_id = json_body.dig("data", "id")

      post "/api/v1/payout_accounts",
           params: {
             payout_account: {
               account_type: "bank",
               bank_code: "01",
               bank_name: "Test Bank",
               account_name: "Jane Doe",
               account_number: "1234567890"
             }
           },
           headers: headers,
           as: :json
      expect(response).to have_http_status(:created)
      second_id = json_body.dig("data", "id")

      get "/api/v1/payout_accounts", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(2)

      patch "/api/v1/payout_accounts/#{second_id}",
            params: { payout_account: { bank_name: "Updated Bank" } },
            headers: headers,
            as: :json
      expect(response).to have_http_status(:ok)
      expect(PayoutAccount.find(second_id).bank_name).to eq("Updated Bank")

      patch "/api/v1/payout_accounts/#{second_id}/set_primary", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(PayoutAccount.find(second_id).primary).to be(true)
      expect(PayoutAccount.find(first_id).primary).to be(false)

      delete "/api/v1/payout_accounts/#{first_id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
      expect(PayoutAccount.exists?(first_id)).to be(false)
    end
  end
end
