# frozen_string_literal: true

class UserPrivateSerializer < ApplicationSerializer
  set_type :user

  attributes :email, :role, :kyc_status, :status, :first_name, :last_name, :phone_number

  attribute :created_at do |user|
    user.created_at&.iso8601
  end

  attribute :updated_at do |user|
    user.updated_at&.iso8601
  end
end
