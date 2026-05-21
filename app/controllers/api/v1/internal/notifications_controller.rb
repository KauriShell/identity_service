# frozen_string_literal: true

module Api
  module V1
    module Internal
      class NotificationsController < BaseController
        skip_before_action :authenticate_api_v1_user!
        before_action :authenticate_service!

        def create
          user = User.find_by(id: params.require(:user_id))
          return render_error(status: :not_found, title: "Not Found", detail: "User not found") unless user

          notification = user.notifications.create!(
            notification_type: params.require(:notification_type),
            title: params.require(:title),
            body: params[:body],
            related_resource_type: params[:related_resource_type],
            related_resource_id: params[:related_resource_id],
            deep_link: params[:deep_link],
            metadata: params[:metadata].presence || {}
          )

          render json: {
            data: {
              id: notification.id,
              notification_type: notification.notification_type,
              title: notification.title
            }
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_error(status: :unprocessable_entity, title: "Unprocessable Entity", detail: e.record.errors.full_messages.to_sentence)
        end
      end
    end
  end
end
