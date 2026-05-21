# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "authentication" do
    subject { get "/api/v1/users" }

    include_examples "requires_auth"
  end

  describe "index" do
    it "allows admins to list users" do
      admin = create(:admin)
      create_list(:user, 2)

      get "/api/v1/users", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to be >= 2
    end

    it "forbids members" do
      user = create(:user)

      get "/api/v1/users", headers: auth_headers(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "show" do
    it "shows own profile" do
      user = create(:user)

      get "/api/v1/users/#{user.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("data", "id")).to eq(user.id)
      expect(json_body.dig("data", "attributes").key?("metadata")).to be(false)
    end

    it "includes metadata when an admin views another user" do
      admin = create(:admin)
      other = create(:user, metadata: { "tier" => "gold" })

      get "/api/v1/users/#{other.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("data", "attributes", "metadata")).to eq({ "tier" => "gold" })
    end
  end

  describe "update" do
    it "updates own profile" do
      user = create(:user)
      params = { user: { first_name: "Updated" } }

      patch "/api/v1/users/#{user.id}", params: params, headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("data", "attributes", "firstName")).to eq("Updated")
    end
  end

  describe "destroy" do
    it "soft deletes as admin" do
      admin = create(:admin)
      user = create(:user)

      delete "/api/v1/users/#{user.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(user.reload.discarded_at).to be_present
    end

    it "rotates JTI so access tokens issued before discard are rejected" do
      admin = create(:admin)
      target = create(:user)
      old_headers = auth_headers(target)
      old_jti = target.jti

      delete "/api/v1/users/#{target.id}", headers: auth_headers(admin)

      expect(target.reload.jti).not_to eq(old_jti)
      get "/api/v1/users/#{target.id}", headers: old_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
