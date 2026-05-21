# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devices", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  it "registers and deletes a device" do
    post "/api/v1/devices",
         params: {
           device: {
             platform: "android",
             push_token: "ExponentPushToken[test-token-123]",
             device_name: "Samsung A24",
             app_version: "1.0.0",
             locale: "en-KE"
           }
         },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:created)
    device_id = json_body.dig("data", "id")
    expect(Device.exists?(device_id)).to be(true)

    delete "/api/v1/devices/#{device_id}", headers: headers, as: :json

    expect(response).to have_http_status(:no_content)
    expect(Device.exists?(device_id)).to be(false)
  end
end
