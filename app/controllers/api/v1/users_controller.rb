# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: %i[show update destroy]

      def index
        authorize User
        payload = IdentityService::ApiCache.fetch(
          resource: "users_index",
          parts: { viewer_id: current_user.id, viewer_role: current_user.role },
          expires_in: 30.seconds
        ) do
          users = policy_scope(User).includes(:kyc_verifications)
          UserSerializer.new(users).serializable_hash
        end
        render json: payload
      end

      def show
        authorize @user
        payload = IdentityService::ApiCache.fetch(
          resource: "users_show",
          parts: { viewer_id: current_user.id, viewer_role: current_user.role, user_id: @user.id },
          expires_in: 30.seconds
        ) do
          if current_user.role_admin? || current_user.role_superadmin?
            UserSerializer.new(@user).serializable_hash
          else
            UserPrivateSerializer.new(@user).serializable_hash
          end
        end
        render json: payload
      end

      def permissions
        authorize @user, :show?
        render json: {
          data: {
            id: @user.id,
            type: "permissions",
            attributes: {
              permissions: permissions_for(@user)
            }
          }
        }, status: :ok
      end

      def update
        authorize @user
        @user.update!(user_params)
        serializer = current_user.role_admin? || current_user.role_superadmin? ? UserSerializer : UserPrivateSerializer
        render json: serializer.new(@user).serializable_hash
      end

      def destroy
        authorize @user
        @user.revoke_tokens!
        @user.discard
        head :no_content
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        permitted = policy(@user || User).permitted_attributes
        params.require(:user).permit(permitted)
      end

      def permissions_for(user)
        Identity::Permissions.for(user)
      end
    end
  end
end
