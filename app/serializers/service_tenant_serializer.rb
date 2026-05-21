# frozen_string_literal: true

class ServiceTenantSerializer < ApplicationSerializer
  set_type :serviceTenant

  attributes :name, :description, :active

  attribute :created_at do |tenant|
    tenant.created_at&.iso8601
  end

  attribute :updated_at do |tenant|
    tenant.updated_at&.iso8601
  end
end
