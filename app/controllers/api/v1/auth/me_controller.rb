# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MeController < BaseController
        def show
          render json: UserPrivateSerializer.new(current_user).serializable_hash, status: :ok
        end
      end
    end
  end
end
