# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin_or_superadmin?
  end

  def show?
    owns_record? || admin_or_superadmin?
  end

  def update?
    owns_record? || admin_or_superadmin?
  end

  def destroy?
    admin_or_superadmin?
  end

  def permitted_attributes
    attrs = %i[first_name last_name phone_number]
    if admin_or_superadmin?
      attrs += %i[status kyc_status metadata]
    end
    attrs << :role if superadmin?
    attrs
  end

  class Scope < Scope
    def resolve
      return scope.all if admin_or_superadmin?
      scope.where(id: user.id)
    end

    private

    def admin_or_superadmin?
      user&.role_admin? || user&.role_superadmin?
    end
  end

  private

  def owns_record?
    return false unless user.present? && record.present?
    return true if user.equal?(record)

    record.id.present? && user.id.present? && record.id == user.id
  end

  def admin_or_superadmin?
    user&.role_admin? || user&.role_superadmin?
  end

  def superadmin?
    user&.role_superadmin?
  end
end
