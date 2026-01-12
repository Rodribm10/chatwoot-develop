class Captain::InboxAutomationPolicy < ApplicationPolicy
  def index?
    captain_permissions?
  end

  def show?
    captain_permissions?
  end

  def create?
    captain_permissions?
  end

  def update?
    captain_permissions?
  end

  def destroy?
    captain_permissions?
  end

  private

  def captain_permissions?
    user.administrator? || user.agent?
  end
end
