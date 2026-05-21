# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Users API", type: :request do
  path "/api/v1/users" do
    get "List users" do
      tags "Users"
      description "Admin and superadmin only. Returns all users with optional metadata on each record."
      security [bearerAuth: []]
      produces "application/json"

      response "200", "users listed" do
        let(:Authorization) { auth_headers(admin)["Authorization"] }
        let(:admin) { create(:admin) }

        before { create_list(:user, 2) }

        run_test!
      end

      response "403", "forbidden for members" do
        let(:Authorization) { auth_headers(member)["Authorization"] }
        let(:member) { create(:user) }

        run_test!
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, type: :string, format: :uuid, required: true

    get "Show user" do
      tags "Users"
      description "Members see their own profile (private attributes). Admins see full user including metadata when viewing others."
      security [bearerAuth: []]
      produces "application/json"

      response "200", "user found" do
        let(:Authorization) { auth_headers(user)["Authorization"] }
        let(:user) { create(:user) }
        let(:id) { user.id }

        run_test!
      end
    end

    patch "Update user" do
      tags "Users"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              phone_number: { type: :string },
              metadata: { type: :object },
              status: { type: :string },
              kyc_status: { type: :string },
              role: { type: :string }
            },
            description: "Admins may set status, kyc_status, metadata; superadmin may set role."
          }
        },
        required: ["user"]
      }

      response "200", "updated" do
        let(:Authorization) { auth_headers(user)["Authorization"] }
        let(:user) { create(:user) }
        let(:id) { user.id }
        let(:body) { { user: { first_name: "Swagger" } } }

        run_test!
      end
    end

    delete "Soft-delete user" do
      tags "Users"
      description "Admin or superadmin only. Discards the user, revokes tokens, and rotates JWT identifier."
      security [bearerAuth: []]

      response "204", "deleted" do
        let(:Authorization) { auth_headers(admin)["Authorization"] }
        let(:admin) { create(:admin) }
        let(:target) { create(:user) }
        let(:id) { target.id }

        run_test!
      end
    end
  end
end
