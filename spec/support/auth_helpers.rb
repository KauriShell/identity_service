# frozen_string_literal: true

module AuthHelpers
  def auth_headers(user)
    if user.respond_to?(:confirmed?) && !user.confirmed?
      user.update_column(:confirmed_at, Time.current)
      user.reload
    end

    scope = :api_v1_user
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, scope, nil)
    {
      "Authorization" => "Bearer #{token}",
      "HTTP_AUTHORIZATION" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  # Params root key must match the Devise mapping (e.g. :api_v1_user for namespaced routes).
  def devise_user_params(attributes)
    key = Devise.mappings.fetch(:api_v1_user).singular
    { key => attributes }
  end
end

RSpec.shared_examples "requires_auth" do
  it "returns 401 unauthorized" do
    subject
    expect(response).to have_http_status(:unauthorized)
  end
end
