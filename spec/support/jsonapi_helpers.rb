# frozen_string_literal: true

module JsonapiHelpers
  def json_body
    JSON.parse(response.body)
  end
end

RSpec.shared_examples "jsonapi_response" do
  it "includes a jsonapi data or errors envelope" do
    body = json_body
    expect(body).to be_a(Hash)
    expect(body.key?("data") || body.key?("errors")).to be(true)
  end
end
