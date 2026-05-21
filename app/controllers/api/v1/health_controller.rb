# frozen_string_literal: true

module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_api_v1_user!

      def show
        checks = {
          database_primary: check_primary,
          database_replica: check_replica
        }

        payload = {
          data: {
            type: "health",
            id: "identity_service",
            attributes: {
              status: "ok",
              checks: checks
            }
          }
        }

        render json: payload
      end

      private

      def check_primary
        ApplicationRecord.connected_to(role: :writing) do
          ApplicationRecord.connection.execute("SELECT 1")
          { status: "ok", role: "primary" }
        end
      rescue StandardError => e
        { status: "error", role: "primary", error: e.message }
      end

      def check_replica
        ApplicationRecord.connected_to(role: :reading) do
          result = ApplicationRecord.connection.execute("SELECT pg_is_in_recovery() AS is_replica")
          is_replica = ActiveModel::Type::Boolean.new.cast(result.first["is_replica"])
          {
            status: is_replica ? "ok" : "warning",
            role: "replica",
            is_replica: is_replica,
            note: is_replica ? nil : "Connected host is not a replica"
          }
        end
      rescue StandardError => e
        { status: "error", role: "replica", error: e.message }
      end
    end
  end
end
