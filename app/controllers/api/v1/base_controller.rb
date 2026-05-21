# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      include ServiceAuthenticatable

      before_action :authenticate_api_v1_user!, unless: :skip_user_auth?

      alias_method :current_user, :current_api_v1_user

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
      rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

      def render_error(status:, title:, detail:, source: nil)
        http_status = normalize_status(status)
        error = {
          status: Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(http_status).to_s,
          title: title,
          detail: detail
        }
        error[:source] = source if source
        render json: { errors: [error] }, status: http_status
      end

      private

      def skip_user_auth?
        devise_controller?
      end

      def render_not_found(error)
        render_error(status: :not_found, title: "Not Found", detail: "Resource not found.")
      end

      def render_forbidden(error)
        render_error(status: :forbidden, title: "Forbidden", detail: error.message)
      end

      def normalize_status(status)
        sym = status.to_sym
        return :unprocessable_content if sym == :unprocessable_entity

        sym
      end

      def render_record_invalid(error)
        errors = error.record.errors.map do |record_error|
          {
            status: "422",
            title: "Unprocessable Entity",
            detail: record_error.full_message,
            source: { pointer: "/data/attributes/#{record_error.attribute}" }
          }
        end
        render json: { errors: errors }, status: :unprocessable_content
      end
    end
  end
end
