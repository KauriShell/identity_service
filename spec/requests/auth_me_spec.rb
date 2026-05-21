# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth Me", type: :request do
  it "returns current authenticated user" do
    user = create(:user)

    get "/api/v1/auth/me", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(json_body.dig("data", "id")).to eq(user.id)
    expect(json_body.dig("data", "attributes", "email")).to eq(user.email)
  end
end
