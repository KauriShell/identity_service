# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceAuthenticatable, type: :controller do
  controller(ActionController::API) do
    include ServiceAuthenticatable

    def render_error(status:, title:, detail:, source: nil)
      error = {
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(status).to_s,
        title: title,
        detail: detail
      }
      error[:source] = source if source
      render json: { errors: [error] }, status: status
    end

    before_action :authenticate_service!

    def index
      head :ok
    end
  end

  include JsonapiHelpers

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  describe "GET #index" do
    it "returns unauthorized when X-Service-Token is missing" do
      get :index

      expect(response).to have_http_status(:unauthorized)
      expect(json_body.dig("errors", 0, "detail")).to eq("Service token is missing or invalid.")
    end

    it "returns unauthorized when the token does not match an active tenant" do
      request.headers["X-Service-Token"] = "not-a-valid-token"

      get :index

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows access when X-Service-Token matches an active service tenant" do
      raw = SecureRandom.hex(32)
      create(:service_tenant, token_digest: ServiceTenant.hash_token(raw), active: true)
      request.headers["X-Service-Token"] = raw

      get :index

      expect(response).to have_http_status(:ok)
    end

    it "rejects tokens for inactive tenants" do
      raw = SecureRandom.hex(32)
      create(:service_tenant, token_digest: ServiceTenant.hash_token(raw), active: false)
      request.headers["X-Service-Token"] = raw

      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
