# frozen_string_literal: true

module Api
  module V1
    class SessionsController < Devise::SessionsController
      # JWT clients are never "session signed-in"; Devise's check runs before Warden has
      # the user from the Bearer token and incorrectly returns 401 on DELETE sign_out.
      skip_before_action :verify_signed_out_user, only: :destroy

      # JSON API: no flash/session. devise-jwt revokes the access token
      # (denylist / JTI); we revoke all refresh tokens so /auth/refresh cannot mint tokens.
      def destroy
        user = current_api_v1_user
        signed_out = Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
        TokenRevocationService.revoke_all_refresh_tokens!(user) if user && signed_out
        yield if block_given?
        respond_to_on_destroy(non_navigational_status: :no_content)
      end
    end
  end
end
