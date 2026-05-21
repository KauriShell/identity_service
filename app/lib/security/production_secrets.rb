# frozen_string_literal: true

module Security
  module ProductionSecrets
    DENYLIST = [
      "change-me",
      "change_me",
      "development_escrow_service_token",
      "replace_with_32_byte_key"
    ].freeze

    REQUIRED = %w[
      SECRET_KEY_BASE
      DEVISE_JWT_SECRET_KEY
      DEVISE_PEPPER
      SERVICE_TOKEN_SALT
    ].freeze

    module_function

    def verify!
      return unless Rails.env.production?

      REQUIRED.each do |key|
        value = ENV[key].to_s
        if value.blank?
          raise "SECURITY: #{key} must be set in production"
        end
        if denylisted?(value)
          raise "SECURITY: #{key} uses a forbidden default value in production"
        end
      end

      jobs_password = ENV.fetch("MISSION_CONTROL_JOBS_PASSWORD", "")
      if jobs_password.blank? || denylisted?(jobs_password)
        raise "SECURITY: MISSION_CONTROL_JOBS_PASSWORD must be a strong unique value in production"
      end
    end

    def denylisted?(value)
      normalized = value.to_s.strip.downcase
      DENYLIST.any? { |entry| normalized == entry || normalized.include?(entry) }
    end
  end
end
