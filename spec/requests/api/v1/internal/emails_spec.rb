# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Internal Emails API", type: :request do
  let(:service_token) { SecureRandom.hex(32) }
  let(:user) { create(:user, email: "notify-me@trustbridge.test") }

  before do
    create(:service_tenant, name: "escrow_service", token_digest: ServiceTenant.hash_token(service_token), active: true)
    ActiveJob::Base.queue_adapter = :test
  end

  it "queues a transactional email for a user" do
    expect do
      post "/api/v1/internal/emails",
           params: {
             user_id: user.id,
             subject: "Test payout complete",
             body: "Your escrow payout has been sent."
           },
           headers: { "X-Service-Token" => service_token },
           as: :json
    end.to have_enqueued_job(ActionMailer::MailDeliveryJob)

    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body.dig("data", "queued")).to be(true)
  end

  it "returns 422 when user has no email" do
    user.update_columns(email: "")

    post "/api/v1/internal/emails",
         params: { user_id: user.id, subject: "Hi", body: "Body" },
         headers: { "X-Service-Token" => service_token },
         as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns 404 when user is missing" do
    post "/api/v1/internal/emails",
         params: { user_id: SecureRandom.uuid, subject: "Hi", body: "Body" },
         headers: { "X-Service-Token" => service_token },
         as: :json

    expect(response).to have_http_status(:not_found)
  end
end
