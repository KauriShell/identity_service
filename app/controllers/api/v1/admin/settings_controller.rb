# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SettingsController < BaseController
        before_action :require_admin!

        IDENTITY_SCHEDULED_JOBS = [
          {
            name: "clear_solid_queue_finished_jobs",
            class_name: "SolidQueue::Job",
            cron_expression: "12 * * * *",
            queue: "default",
            service: "identity_service",
            description: "Clear finished Solid Queue jobs in batches",
            enabled: Rails.env.production?,
            last_run_at: nil,
            next_run_at: nil,
            last_run_status: nil
          }
        ].freeze

        def jobs
          payload = IdentityService::ApiCache.fetch(
            resource: "admin_settings_jobs",
            parts: {},
            expires_in: 60.seconds
          ) do
            { data: IDENTITY_SCHEDULED_JOBS }
          end
          render json: payload, status: :ok
        end

        def kyc_tiers
          payload = IdentityService::ApiCache.fetch(
            resource: "admin_settings_kyc_tiers",
            parts: {},
            expires_in: 60.seconds
          ) do
            { data: tiers_payload }
          end
          render json: payload, status: :ok
        end

        def update_kyc_tier
          reason = params[:reason].to_s
          return render_error(status: :unprocessable_entity, title: "Unprocessable Entity", detail: "Reason must be at least 10 characters.") if reason.strip.length < 10

          tier = params[:tier].to_i
          row = tiers_payload.find { |item| item[:tier] == tier }
          return render_error(status: :not_found, title: "Not Found", detail: "KYC tier not found.") if row.nil?

          row[:max_escrow_cents] = integer_or(row[:max_escrow_cents], params[:max_escrow_cents])
          row[:monthly_volume_cents] = integer_or(row[:monthly_volume_cents], params[:monthly_volume_cents])
          row[:required_documents] = Array(params[:required_documents]).map(&:to_s) if params.key?(:required_documents)
          row[:payout_methods] = Array(params[:payout_methods]).map(&:to_s) if params.key?(:payout_methods)

          render json: row, status: :ok
        end

        private

        def require_admin!
          return if current_user.role_admin? || current_user.role_superadmin?

          render_error(status: :forbidden, title: "Forbidden", detail: "Admin access required.")
        end

        def integer_or(default, value)
          return default if value.nil?

          Integer(value)
        rescue StandardError
          default
        end

        def tiers_payload
          [
            {
              tier: 0,
              label: "Tier 0 - Unverified",
              max_escrow_cents: env_int("NEXT_PUBLIC_KYC_TIER_0_LIMIT_CENTS", 1_000_000),
              monthly_volume_cents: env_int("NEXT_PUBLIC_KYC_TIER_0_LIMIT_CENTS", 1_000_000),
              required_documents: [],
              payout_methods: ["mpesa"]
            },
            {
              tier: 1,
              label: "Tier 1 - Basic",
              max_escrow_cents: env_int("NEXT_PUBLIC_KYC_TIER_1_LIMIT_CENTS", 15_000_000),
              monthly_volume_cents: 20_000_000,
              required_documents: ["national_id"],
              payout_methods: %w[mpesa pesalink]
            },
            {
              tier: 2,
              label: "Tier 2 - Verified",
              max_escrow_cents: env_int("NEXT_PUBLIC_KYC_TIER_2_LIMIT_CENTS", 200_000_000),
              monthly_volume_cents: 300_000_000,
              required_documents: %w[national_id selfie kra_pin],
              payout_methods: %w[mpesa pesalink]
            },
            {
              tier: 3,
              label: "Tier 3 - Business",
              max_escrow_cents: 0,
              monthly_volume_cents: 0,
              required_documents: %w[business_registration certificate_of_incorporation],
              payout_methods: %w[mpesa pesalink]
            }
          ]
        end

        def env_int(name, fallback)
          Integer(ENV.fetch(name, fallback.to_s))
        rescue StandardError
          fallback
        end
      end
    end
  end
end
