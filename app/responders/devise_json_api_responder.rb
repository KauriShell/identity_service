# frozen_string_literal: true

class DeviseJsonApiResponder < ActionController::Responder
  def to_json(*_args)
    if has_errors?
      render_error_response
    else
      render_success_response
    end
  end

  private

  def render_error_response
    errors = resource.errors.map do |error|
      {
        status: "422",
        title: "Unprocessable Entity",
        detail: error.full_message,
        source: { pointer: "/data/attributes/#{error.attribute}" }
      }
    end

    controller.render json: { errors: errors }, status: :unprocessable_content
  end

  def render_success_response
    if resource.is_a?(User)
      payload = { data: UserPrivateSerializer.new(resource).serializable_hash[:data] }

      if issue_refresh_token?
        refresh = RefreshTokenIssuer.call(resource)
        payload[:meta] = {
          refreshToken: refresh.token,
          refreshTokenExpiresAt: refresh.expires_at.iso8601
        }
      end

      controller.render json: payload, status: options[:status] || :ok
    else
      controller.render json: { meta: {} }, status: options[:status] || :ok
    end
  end

  def issue_refresh_token?
    return false if resource.respond_to?(:confirmed?) && !resource.confirmed?

    controller.is_a?(Devise::SessionsController) && controller.action_name == "create" ||
      controller.is_a?(Devise::RegistrationsController) && controller.action_name == "create"
  end
end
