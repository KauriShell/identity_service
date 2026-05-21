# frozen_string_literal: true

module Api
  module V1
    module Internal
      # Service-to-service only (X-Service-Token + ServiceTenant). Used by escrow_service
      # to resolve user profile fields without forwarding end-user JWTs through proxies.
      class UsersController < ApplicationController
        include ServiceAuthenticatable

        before_action :authenticate_service!

        def show
          user = User.find_by(id: params[:id])
          unless user
            return render json: { error: "User not found" }, status: :not_found
          end

          render json: {
            data: {
              id: user.id,
              attributes: {
                first_name: user.first_name,
                last_name: user.last_name,
                phone_number: user.phone_number,
                email: user.email,
                role: user.role,
                kyc_status: user.kyc_status,
                kyc_tier: kyc_tier_for(user)
              }
            }
          }, status: :ok
        end

        private

        def kyc_tier_for(user)
          case user.kyc_status
          when "approved" then 3
          when "under_review", "submitted" then 2
          when "rejected" then 0
          else 1
          end
        end
      end
    end
  end
end
