# frozen_string_literal: true

module ServiceAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :set_current_service_tenant
    around_action :tag_service_tenant
  end

  def authenticate_service!
    return if current_service_tenant&.active?

    render_error(
      status: :unauthorized,
      title: "Unauthorized",
      detail: "Service token is missing or invalid."
    )
  end

  def current_service_tenant
    @current_service_tenant
  end

  private

  def set_current_service_tenant
    raw_token = request.headers["X-Service-Token"]
    return if raw_token.blank?

    digest = ServiceTenant.hash_token(raw_token)
    @current_service_tenant = ServiceTenant.active.find_by(token_digest: digest)
  end

  def tag_service_tenant(&block)
    service_name = current_service_tenant&.name || "unknown"
    Rails.logger.tagged("service:#{service_name}", &block)
  end
end
