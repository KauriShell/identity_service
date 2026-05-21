# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Service tenants API", type: :request do
  path "/api/v1/service_tenants" do
    get "List service tenants" do
      tags "Service tenants"
      description "Superadmin only."
      security [bearerAuth: []]
      produces "application/json"

      response "200", "tenants listed" do
        let(:Authorization) { auth_headers(superadmin)["Authorization"] }
        let(:superadmin) { create(:superadmin) }

        before { create_list(:service_tenant, 2) }

        run_test!
      end
    end

    post "Create service tenant" do
      tags "Service tenants"
      description "Superadmin only. Returns a one-time raw service token in `meta.serviceToken`."
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          service_tenant: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string }
            },
            required: ["name"]
          }
        },
        required: ["service_tenant"]
      }

      response "201", "tenant created" do
        let(:Authorization) { auth_headers(superadmin)["Authorization"] }
        let(:superadmin) { create(:superadmin) }
        let(:body) do
          { service_tenant: { name: "swagger-tenant-#{SecureRandom.hex(4)}", description: "API access" } }
        end

        run_test!
      end
    end
  end

  path "/api/v1/service_tenants/{id}" do
    parameter name: :id, in: :path, type: :string, format: :uuid, required: true

    get "Show service tenant" do
      tags "Service tenants"
      security [bearerAuth: []]
      produces "application/json"

      response "200", "tenant found" do
        let(:Authorization) { auth_headers(superadmin)["Authorization"] }
        let(:superadmin) { create(:superadmin) }
        let(:tenant) { create(:service_tenant, name: "payments") }
        let(:id) { tenant.id }

        run_test!
      end
    end

    patch "Update service tenant" do
      tags "Service tenants"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          service_tenant: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              active: { type: :boolean }
            }
          }
        },
        required: ["service_tenant"]
      }

      response "200", "updated" do
        let(:Authorization) { auth_headers(superadmin)["Authorization"] }
        let(:superadmin) { create(:superadmin) }
        let(:tenant) { create(:service_tenant, name: "old") }
        let(:id) { tenant.id }
        let(:body) { { service_tenant: { name: "new-name" } } }

        run_test!
      end
    end

    delete "Deactivate service tenant" do
      tags "Service tenants"
      description "Sets active to false (soft deactivate)."
      security [bearerAuth: []]

      response "204", "deactivated" do
        let(:Authorization) { auth_headers(superadmin)["Authorization"] }
        let(:superadmin) { create(:superadmin) }
        let(:tenant) { create(:service_tenant, active: true) }
        let(:id) { tenant.id }

        run_test!
      end
    end
  end
end
