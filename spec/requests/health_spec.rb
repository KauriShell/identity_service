# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  it "returns ok" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
    expect(json_body.dig("data", "attributes", "status")).to eq("ok")
  end

  it_behaves_like "jsonapi_response" do
    before { get "/api/v1/health" }
  end
end
