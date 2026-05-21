# frozen_string_literal: true

class ServiceTenantPolicy < ApplicationPolicy
  def index?
    superadmin?
  end

  def show?
    superadmin?
  end

  def create?
    superadmin?
  end

  def update?
    superadmin?
  end

  def destroy?
    superadmin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.role_superadmin?
      scope.none
    end
  end

  private

  def superadmin?
    user&.role_superadmin?
  end
end
