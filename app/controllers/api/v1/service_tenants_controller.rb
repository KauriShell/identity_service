# frozen_string_literal: true

module Api
  module V1
    class ServiceTenantsController < BaseController
      before_action :set_service_tenant, only: %i[show update destroy]

      def index
        authorize ServiceTenant
        payload = IdentityService::ApiCache.fetch(
          resource: "service_tenants_index",
          parts: { viewer_id: current_user.id, viewer_role: current_user.role },
          expires_in: 30.seconds
        ) do
          tenants = policy_scope(ServiceTenant)
          ServiceTenantSerializer.new(tenants).serializable_hash
        end
        render json: payload
      end

      def show
        authorize @service_tenant
        payload = IdentityService::ApiCache.fetch(
          resource: "service_tenants_show",
          parts: { viewer_id: current_user.id, viewer_role: current_user.role, id: @service_tenant.id },
          expires_in: 30.seconds
        ) do
          ServiceTenantSerializer.new(@service_tenant).serializable_hash
        end
        render json: payload
      end

      def create
        authorize ServiceTenant
        raw_token = ServiceTenant.generate_token
        tenant = ServiceTenant.new(service_tenant_params.merge(
          token_digest: ServiceTenant.hash_token(raw_token)
        ))
        tenant.save!
        render json: ServiceTenantSerializer.new(tenant).serializable_hash.merge(
          meta: { serviceToken: raw_token }
        ), status: :created
      end

      def update
        authorize @service_tenant
        @service_tenant.update!(service_tenant_params)
        render json: ServiceTenantSerializer.new(@service_tenant).serializable_hash
      end

      def destroy
        authorize @service_tenant
        @service_tenant.update!(active: false)
        head :no_content
      end

      private

      def set_service_tenant
        @service_tenant = ServiceTenant.find(params[:id])
      end

      def service_tenant_params
        params.require(:service_tenant).permit(:name, :description, :active)
      end
    end
  end
end
