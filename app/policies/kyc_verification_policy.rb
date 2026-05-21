# frozen_string_literal: true

class KycVerificationPolicy < ApplicationPolicy
  def submit?
    user.present?
  end

  def status?
    user.present?
  end

  def index?
    admin_or_superadmin?
  end

  def review?
    admin_or_superadmin?
  end

  class Scope < Scope
    def resolve
      return scope.all if admin_or_superadmin?
      scope.where(user_id: user.id)
    end

    private

    def admin_or_superadmin?
      user&.role_admin? || user&.role_superadmin?
    end
  end

  private

  def admin_or_superadmin?
    user&.role_admin? || user&.role_superadmin?
  end
end
