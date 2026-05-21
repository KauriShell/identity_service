# frozen_string_literal: true

# Only loaded when rswag-ui is bundled (development/test). Production images omit it.
if defined?(Rswag::Ui)
  Rswag::Ui.configure do |c|
    c.openapi_endpoint "/api-docs/v1/swagger.yaml", "Identity Service API v1"
    c.config_object["urls"] = [
      { url: "/api-docs/v1/swagger.yaml", name: "Identity Service API v1" }
    ]
  end
end
