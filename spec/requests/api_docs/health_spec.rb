# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Health", type: :request do
  path "/api/v1/health" do
    get "Health check" do
      tags "Health"
      produces "application/json"

      response "200", "ok" do
        run_test!
      end
    end
  end
end
