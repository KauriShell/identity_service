# frozen_string_literal: true

module Api
  module V1
    class KycController < BaseController
      before_action :set_verification, only: :review

      def submit
        authorize KycVerification, :submit?
        verification = KycSubmissionService.call(
          user: current_user,
          document_type: kyc_params.fetch(:document_type),
          documents: kyc_params[:documents]
        )
        render json: KycVerificationSerializer.new(verification).serializable_hash, status: :created
      end

      def status
        authorize KycVerification, :status?
        payload = IdentityService::ApiCache.fetch(
          resource: "kyc_status",
          parts: { user_id: current_user.id, role: current_user.role },
          expires_in: 15.seconds
        ) do
          {
            data: {
              type: "kycStatus",
              id: current_user.id,
              attributes: { kycStatus: current_user.kyc_status }
            }
          }
        end
        render json: payload
      end

      def index
        authorize KycVerification, :index?
        page = params.fetch(:page, 1).to_i
        size = params.fetch(:size, 20).to_i
        size = 100 if size > 100
        offset = (page - 1) * size

        payload = IdentityService::ApiCache.fetch(
          resource: "kyc_index",
          parts: { viewer_id: current_user.id, viewer_role: current_user.role, page: page, size: size },
          expires_in: 30.seconds
        ) do
          scope = KycVerification
                  .includes(:user)
                  .where(status: %i[submitted under_review])
          total = scope.count

          verifications = scope.order(created_at: :asc).limit(size).offset(offset)
          response = KycVerificationAdminSerializer.new(verifications).serializable_hash
          response[:meta] = { page: page, size: size, total: total }
          response
        end
        render json: payload
      end

      def review
        authorize @verification, :review?
        verification = KycReviewService.call(
          verification: @verification,
          reviewer: current_user,
          status: review_params.fetch(:status),
          notes: review_params[:notes]
        )
        render json: KycVerificationAdminSerializer.new(verification).serializable_hash
      end

      private

      def set_verification
        @verification = KycVerification.find(params[:id])
      end

      def kyc_params
        params.require(:kyc).permit(:document_type, documents: [])
      end

      def review_params
        params.require(:kyc).permit(:status, :notes)
      end
    end
  end
end
