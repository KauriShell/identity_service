# frozen_string_literal: true

module Api
  module V1
    module Internal
      class EmailsController < BaseController
        skip_before_action :authenticate_api_v1_user!
        before_action :authenticate_service!

        def create
          user = User.find_by(id: params.require(:user_id))
          return render_error(status: :not_found, title: "Not Found", detail: "User not found") unless user
          return render_error(status: :unprocessable_entity, title: "Unprocessable Entity", detail: "User has no email") if user.email.blank?

          UserMailer.with(
            to: user.email,
            subject: params.require(:subject),
            body: params.require(:body)
          ).transactional.deliver_later

          render json: { data: { queued: true, to: user.email } }, status: :accepted
        end
      end
    end
  end
end
