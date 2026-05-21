# frozen_string_literal: true

module Api
  module V1
    class PayoutAccountsController < BaseController
      before_action :set_account, only: %i[update destroy set_primary]

      def index
        render json: { data: current_user.payout_accounts.order(created_at: :desc).map { |row| serialize(row) } }, status: :ok
      end

      def create
        account = current_user.payout_accounts.new(account_params)
        account.primary = true if current_user.payout_accounts.none?
        account.save!
        render json: { data: serialize(account) }, status: :created
      end

      def update
        @account.update!(account_params)
        render json: { data: serialize(@account) }, status: :ok
      end

      def destroy
        @account.destroy!
        if current_user.payout_accounts.where(primary: true).none?
          current_user.payout_accounts.order(created_at: :asc).first&.update!(primary: true)
        end
        head :no_content
      end

      def set_primary
        @account.update!(primary: true)
        render json: { data: serialize(@account.reload) }, status: :ok
      end

      private

      def set_account
        @account = current_user.payout_accounts.find(params[:id])
      end

      def account_params
        params.require(:payout_account).permit(:account_type, :phone_number, :bank_code, :bank_name, :account_name, :account_number)
      end

      def serialize(row)
        {
          id: row.id,
          account_type: row.account_type,
          phone_masked: mask_phone(row.phone_number),
          bank_code: row.bank_code,
          bank_name: row.bank_name,
          account_name: row.account_name,
          account_number_masked: mask_account(row.account_number),
          is_primary: row.primary,
          created_at: row.created_at.iso8601,
          updated_at: row.updated_at.iso8601
        }
      end

      def mask_phone(phone)
        return nil if phone.blank?

        digits = phone.to_s.gsub(/\D/, "")
        "****#{digits.last(4)}"
      end

      def mask_account(account_number)
        return nil if account_number.blank?

        "****#{account_number.to_s.last(4)}"
      end
    end
  end
end
