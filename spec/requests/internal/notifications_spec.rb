# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Internal Notifications API", type: :request do
  let(:user) { create(:user) }
  let(:service_token) { SecureRandom.hex(32) }

  before do
    create(:service_tenant, token_digest: ServiceTenant.hash_token(service_token), active: true)
  end

  describe "POST /api/v1/internal/notifications" do
    it "creates an in-app notification for a user" do
      post "/api/v1/internal/notifications",
           params: {
             user_id: user.id,
             notification_type: "dispute.dispute_assigned",
             title: "Mediator assigned",
             body: "A mediator is reviewing your dispute."
           },
           headers: { "X-Service-Token" => service_token }

      expect(response).to have_http_status(:created)
      expect(user.notifications.count).to eq(1)
    end

    it "rejects missing service token" do
      post "/api/v1/internal/notifications",
           params: { user_id: user.id, notification_type: "test", title: "Hi" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
