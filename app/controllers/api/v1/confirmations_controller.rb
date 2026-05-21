# frozen_string_literal: true

module Api
  module V1
    class ConfirmationsController < Devise::ConfirmationsController
      # Devise confirmation finalizes state (confirmed_at) on a GET endpoint.
      # Force primary DB role for this action to avoid readonly replica errors.
      def show
        ApplicationRecord.connected_to(role: :writing) { super }
      end
    end
  end
end
