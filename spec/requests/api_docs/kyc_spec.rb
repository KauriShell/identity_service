# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "KYC API", type: :request do
  path "/api/v1/kyc/submit" do
    post "Submit KYC documents" do
      tags "KYC"
      description "Multipart upload: document type plus one or more files (PDF/images per server rules)."
      security [bearerAuth: []]
      consumes "multipart/form-data"
      produces "application/json"
      parameter name: "kyc[document_type]", in: :formData, type: :string, required: true,
                description: "Supported types include passport, drivers_license (see server validation)."
      parameter name: "kyc[documents][]", in: :formData, type: :file, required: true

      response "201", "verification created" do
        let(:Authorization) { auth_headers(user)["Authorization"] }
        let(:user) { create(:user) }
        let(:"kyc[document_type]") { "passport" }
        let(:"kyc[documents][]") { fixture_file_upload("kyc.pdf", "application/pdf") }

        run_test!
      end
    end
  end

  path "/api/v1/kyc/status" do
    get "Current KYC status" do
      tags "KYC"
      security [bearerAuth: []]
      produces "application/json"

      response "200", "status" do
        let(:Authorization) { auth_headers(user)["Authorization"] }
        let(:user) { create(:user, kyc_status: :pending) }

        run_test!
      end
    end
  end

  path "/api/v1/kyc" do
    get "List pending KYC reviews" do
      tags "KYC"
      description "Admin: paginated queue of submitted and under_review verifications."
      security [bearerAuth: []]
      produces "application/json"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :size, in: :query, type: :integer, required: false, description: "Max 100"

      response "200", "page of verifications" do
        let(:Authorization) { auth_headers(admin)["Authorization"] }
        let(:admin) { create(:admin) }
        let(:page) { 1 }
        let(:size) { 20 }

        before do
          u = create(:user)
          create(:kyc_verification, user: u, status: :submitted, document_type: :passport)
        end

        run_test!
      end
    end
  end

  path "/api/v1/kyc/{id}/review" do
    parameter name: :id, in: :path, type: :string, format: :uuid, required: true

    patch "Review verification" do
      tags "KYC"
      description "Admin: approve or reject a verification and sync user kyc_status."
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          kyc: {
            type: :object,
            properties: {
              status: { type: :string, enum: %w[approved rejected under_review] },
              notes: { type: :string }
            },
            required: ["status"]
          }
        },
        required: ["kyc"]
      }

      response "200", "review saved" do
        let(:Authorization) { auth_headers(admin)["Authorization"] }
        let(:admin) { create(:admin) }
        let(:verification) { create(:kyc_verification, status: :submitted) }
        let(:id) { verification.id }
        let(:body) { { kyc: { status: "approved", notes: "OK" } } }

        run_test!
      end
    end
  end
end
