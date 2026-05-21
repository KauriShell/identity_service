# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseRoleMiddleware do
  let(:app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["ok"]] } }
  let(:middleware) { described_class.new(app) }

  it "uses primary for unlock GET requests" do
    env = Rack::MockRequest.env_for(
      "http://example.com/api/v1/auth/unlock?unlock_token=invalid",
      "REQUEST_METHOD" => "GET"
    )

    expect(ActiveRecord::Base).to receive(:connected_to).with(role: :writing).and_call_original
    status, = middleware.call(env)
    expect(status).to eq(200)
  end

  it "uses replica for ordinary GET requests" do
    env = Rack::MockRequest.env_for("http://example.com/api/v1/health", "REQUEST_METHOD" => "GET")

    expect(ActiveRecord::Base).to receive(:connected_to).with(role: :reading).and_call_original
    middleware.call(env)
  end
end
