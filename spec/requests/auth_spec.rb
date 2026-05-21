# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "registration" do
    it "registers a user" do
      params = devise_user_params(
        email: "newuser@example.com",
        password: "Password1234!",
        password_confirmation: "Password1234!"
      )

      post "/api/v1/auth/sign_up", params: params, as: :json

      expect(response).to have_http_status(:ok).or have_http_status(:created)
      expect(json_body.dig("data", "attributes", "email")).to eq("newuser@example.com")
      expect(json_body.dig("meta", "refreshToken")).to be_nil
    end
  end

  describe "login" do
    it "authenticates a user" do
      user = create(:user, password: "Password1234!", confirmed_at: Time.current)
      params = devise_user_params(email: user.email, password: "Password1234!")

      post "/api/v1/auth/sign_in", params: params, as: :json

      expect(response).to have_http_status(:ok).or have_http_status(:no_content)
      expect(json_body.dig("data", "id")).to eq(user.id)
      expect(json_body.dig("meta", "refreshToken")).to be_present
    end

    it "rejects login when email is not confirmed" do
      user = create(:user, password: "Password1234!", confirmed_at: nil)
      params = devise_user_params(email: user.email, password: "Password1234!")

      post "/api/v1/auth/sign_in", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "locks the account after repeated failed password attempts" do
      user = create(:user, password: "Password1234!", confirmed_at: Time.current)
      wrong = devise_user_params(email: user.email, password: "WrongPassword123!")

      5.times do
        Rack::Attack.cache.store.clear
        post "/api/v1/auth/sign_in", params: wrong, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      Rack::Attack.cache.store.clear
      post "/api/v1/auth/sign_in",
           params: devise_user_params(email: user.email, password: "Password1234!"),
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(user.reload.access_locked?).to be(true)
    end
  end

  describe "logout" do
    it "revokes the access token" do
      user = create(:user)

      delete "/api/v1/auth/sign_out", headers: auth_headers(user)

      expect(response).to have_http_status(:ok).or have_http_status(:no_content)
    end

    it "denies subsequent API access with the same access token (denylist)" do
      user = create(:user)
      headers = auth_headers(user)

      delete "/api/v1/auth/sign_out", headers: headers

      get "/api/v1/users/#{user.id}", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "revokes all refresh tokens so they cannot mint new access tokens" do
      user = create(:user)
      headers = auth_headers(user)
      refresh = RefreshTokenIssuer.call(user)

      delete "/api/v1/auth/sign_out", headers: headers

      post "/api/v1/auth/refresh", params: { refreshToken: refresh.token }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "refresh token" do
    it "exchanges a refresh token for a new access token" do
      user = create(:user)
      refresh = RefreshTokenIssuer.call(user)

      post "/api/v1/auth/refresh", params: { refreshToken: refresh.token }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("meta", "accessToken")).to be_present
      expect(json_body.dig("meta", "refreshToken")).to be_present
    end

    it "rejects reuse of a refresh token after it has been rotated" do
      user = create(:user)
      refresh = RefreshTokenIssuer.call(user)

      post "/api/v1/auth/refresh", params: { refreshToken: refresh.token }, as: :json
      expect(response).to have_http_status(:ok)

      post "/api/v1/auth/refresh", params: { refreshToken: refresh.token }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "enforces a maximum number of concurrent active refresh tokens" do
      user = create(:user)
      max = Rails.configuration.x.refresh_token_max_active

      Array.new(max + 1) { RefreshTokenIssuer.call(user).token }

      expect(user.refresh_tokens.active.count).to eq(max)

      last = user.refresh_tokens.active.order(created_at: :desc).first
      expect(last).to be_present
    end

    it "rejects expired refresh tokens" do
      user = create(:user)
      raw = SecureRandom.hex(64)
      user.refresh_tokens.create!(
        token_digest: Digest::SHA256.hexdigest(raw),
        expires_at: 1.day.ago
      )

      post "/api/v1/auth/refresh", params: { refreshToken: raw }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects refresh when the user has been discarded (tokens revoked)" do
      user = create(:user)
      refresh = RefreshTokenIssuer.call(user)
      user.discard

      post "/api/v1/auth/refresh", params: { refreshToken: refresh.token }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns forbidden when the user is suspended" do
      user = create(:user, status: :suspended)
      refresh = RefreshTokenIssuer.call(user)

      post "/api/v1/auth/refresh", params: { refreshToken: refresh.token }, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "password reset" do
    it "requests a reset token" do
      user = create(:user)
      params = devise_user_params(email: user.email)

      post "/api/v1/auth/password", params: params, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns the same successful response for unknown emails when paranoid mode is enabled" do
      known = devise_user_params(email: create(:user).email)
      unknown = devise_user_params(email: "nobody-#{SecureRandom.hex(4)}@example.com")

      post "/api/v1/auth/password", params: known, as: :json
      known_response = response.body

      post "/api/v1/auth/password", params: unknown, as: :json
      unknown_response = response.body

      expect(response).to have_http_status(:ok)
      expect(unknown_response).to eq(known_response)
    end
  end
end
