# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting (Rack::Attack)", type: :request do
  before do
    Rack::Attack.cache.store.clear
  end

  it "returns 429 when the login throttle is exceeded for an IP" do
    email = "ratelimit-#{SecureRandom.hex(4)}@example.com"
    params = devise_user_params(email: email, password: "WrongPassword123!")

    5.times do
      post "/api/v1/auth/sign_in", params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    post "/api/v1/auth/sign_in", params: params, as: :json

    expect(response).to have_http_status(:too_many_requests)
    expect(json_body.dig("errors", 0, "title")).to eq("Too Many Requests")
  end

  it "returns 429 when the registration throttle is exceeded for an IP" do
    10.times do |i|
      params = devise_user_params(
        email: "reg-rate-#{i}-#{SecureRandom.hex(4)}@example.com",
        password: "Password1234!",
        password_confirmation: "Password1234!"
      )
      post "/api/v1/auth/sign_up", params: params, as: :json
      expect(response).not_to have_http_status(:too_many_requests)
    end

    post "/api/v1/auth/sign_up",
         params: devise_user_params(
           email: "reg-rate-blocked-#{SecureRandom.hex(4)}@example.com",
           password: "Password1234!",
           password_confirmation: "Password1234!"
         ),
         as: :json

    expect(response).to have_http_status(:too_many_requests)
    expect(json_body.dig("errors", 0, "title")).to eq("Too Many Requests")
  end
end
