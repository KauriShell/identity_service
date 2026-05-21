# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mission Control Jobs UI", type: :request do
  it "is mounted at /jobs" do
    expect { Rails.application.routes.recognize_path("/jobs", method: :get) }.not_to raise_error
  end
end

