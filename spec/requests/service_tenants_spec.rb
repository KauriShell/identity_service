# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ServiceTenants", type: :request do
  let(:superadmin) { create(:superadmin) }
  let(:headers) { auth_headers(superadmin) }

  describe "create" do
    it "allows superadmins" do
      params = { service_tenant: { name: "billing", description: "Billing service" } }

      post "/api/v1/service_tenants", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body.dig("meta", "serviceToken")).to be_present
    end

    it "forbids non-superadmins" do
      admin = create(:admin)
      params = { service_tenant: { name: "billing", description: "Billing service" } }

      post "/api/v1/service_tenants", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "index" do
    it "lists tenants for superadmins" do
      create_list(:service_tenant, 2)

      get "/api/v1/service_tenants", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end

    it "forbids admins" do
      admin = create(:admin)

      get "/api/v1/service_tenants", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "show" do
    it "returns a tenant for superadmins" do
      tenant = create(:service_tenant, name: "payments-api")

      get "/api/v1/service_tenants/#{tenant.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("data", "id")).to eq(tenant.id)
      expect(json_body.dig("data", "attributes", "name")).to eq("payments-api")
    end
  end

  describe "update" do
    it "updates a tenant for superadmins" do
      tenant = create(:service_tenant, name: "old-name")
      params = { service_tenant: { name: "new-name", description: "updated" } }

      patch "/api/v1/service_tenants/#{tenant.id}", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("data", "attributes", "name")).to eq("new-name")
      expect(tenant.reload.name).to eq("new-name")
    end
  end

  describe "destroy" do
    it "soft-deactivates a tenant" do
      tenant = create(:service_tenant, active: true)

      delete "/api/v1/service_tenants/#{tenant.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(tenant.reload.active).to be(false)
    end
  end
end
