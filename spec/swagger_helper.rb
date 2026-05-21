# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Identity Service API",
        version: "v1",
        description: "JSON API for authentication, users, KYC, and service tenants. " \
                      "Authenticated requests use `Authorization: Bearer <JWT>` unless noted."
      },
      servers: [
        {
          url: "http://localhost:3000",
          description: "Local"
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          jsonApiError: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    status: { type: :string },
                    title: { type: :string },
                    detail: { type: :string },
                    source: { type: :object }
                  }
                }
              }
            }
          },
          jsonApiUserData: {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  id: { type: :string, format: :uuid },
                  type: { type: :string },
                  attributes: { type: :object }
                }
              },
              meta: { type: :object }
            }
          }
        }
      },
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
