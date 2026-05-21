# frozen_string_literal: true

module Api
  module V1
    class DevicesController < BaseController
      def create
        row = Device.find_or_initialize_by(push_token: device_params.fetch(:push_token))
        row.assign_attributes(device_params.merge(user_id: current_user.id, last_seen_at: Time.current))
        row.save!

        render json: {
          data: {
            id: row.id,
            platform: row.platform,
            push_token_last4: row.push_token.to_s.last(4),
            created_at: row.created_at.iso8601
          }
        }, status: :created
      end

      def destroy
        row = current_user.devices.find(params[:id])
        row.destroy!
        head :no_content
      end

      private

      def device_params
        params.require(:device).permit(:platform, :push_token, :device_name, :app_version, :locale)
      end
    end
  end
end
