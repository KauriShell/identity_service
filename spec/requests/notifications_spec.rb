# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/notifications" do
    it "lists user notifications and unread count" do
      Notification.create!(user: user, notification_type: "escrow_funded", title: "Escrow funded", body: "Funds received")
      Notification.create!(user: user, notification_type: "escrow_disputed", title: "Disputed", body: "A dispute was raised", read: true, read_at: Time.current)

      get "/api/v1/notifications", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(2)
      expect(json_body.dig("meta", "unread_count")).to eq(1)
    end

    it "filters unread notifications only" do
      Notification.create!(user: user, notification_type: "escrow_funded", title: "Unread", body: "Body")
      Notification.create!(user: user, notification_type: "escrow_disputed", title: "Read", body: "Body", read: true, read_at: Time.current)

      get "/api/v1/notifications", params: { unread_only: true }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
    end
  end

  describe "PATCH /api/v1/notifications/:id/read" do
    it "marks a notification as read" do
      row = Notification.create!(user: user, notification_type: "escrow_funded", title: "Escrow funded")

      patch "/api/v1/notifications/#{row.id}/read", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(row.reload.read).to be(true)
    end
  end

  describe "PATCH /api/v1/notifications/read_all" do
    it "marks all user notifications as read" do
      Notification.create!(user: user, notification_type: "escrow_funded", title: "A")
      Notification.create!(user: user, notification_type: "escrow_disputed", title: "B")

      patch "/api/v1/notifications/read_all", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(user.notifications.where(read: false).count).to eq(0)
    end
  end
end
