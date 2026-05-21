# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RefreshTokensController < BaseController
        skip_before_action :authenticate_api_v1_user!

        def create
          token = params.require(:refreshToken)
          digest = Digest::SHA256.hexdigest(token)
          refresh_token = RefreshToken.find_by(token_digest: digest)

          unless refresh_token&.active?
            return render_error(
              status: :unauthorized,
              title: "Unauthorized",
              detail: "Refresh token is invalid or expired."
            )
          end

          user = refresh_token.user
          if user.discarded? || !user.status_active?
            return render_error(
              status: :forbidden,
              title: "Forbidden",
              detail: "User is not active."
            )
          end

          TokenRevocationService.revoke_refresh_token!(refresh_token)
          new_refresh = RefreshTokenIssuer.call(user)
          access_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

          render json: {
            data: UserPrivateSerializer.new(user).serializable_hash[:data],
            meta: {
              accessToken: access_token,
              expiresIn: Rails.configuration.x.access_token_ttl.to_i,
              refreshToken: new_refresh.token,
              refreshTokenExpiresAt: new_refresh.expires_at.iso8601
            }
          }
        end
      end
    end
  end
end
