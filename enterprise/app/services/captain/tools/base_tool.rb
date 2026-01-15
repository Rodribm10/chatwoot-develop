class Captain::Tools::BaseTool < RubyLLM::Tool
  attr_accessor :assistant, :conversation

  def initialize(assistant, user: nil, conversation: nil)
    @assistant = assistant
    @user = user
    @conversation = conversation
    super()
  end

  def execute(*args, **params)
    # Default implementation to be overridden
  end

  protected

  def resolve_params(args, params)
    # RubyLLM: [params_hash], {}
    # Agents: [context], {params_hash}
    actual_params = if args.first.is_a?(Hash) && params.empty?
                      args.first
                    else
                      params
                    end
    actual_params.with_indifferent_access
  end

  def resolve_context(tool_context)
    if tool_context.respond_to?(:state)
      tool_context.state
    elsif tool_context.is_a?(Hash)
      tool_context
    else
      {}
    end.with_indifferent_access
  end

  def active?
    true
  end

  private

  def user_has_permission(permission)
    return false if @user.blank?

    account_user = AccountUser.find_by(account_id: @assistant.account_id, user_id: @user.id)
    return false if account_user.blank?

    return account_user.custom_role.permissions.include?(permission) if account_user.custom_role.present?

    account_user.administrator? || account_user.agent?
  end
end
