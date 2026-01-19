require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  def initialize(assistant, user: nil, conversation: nil)
    @assistant = assistant
    @user = user
    @conversation = conversation
    super()
  end

  def active?
    # Public tools are always active
    true
  end

  def permissions
    # Override in subclasses to specify required permissions
    # Returns empty array for public tools (no permissions required)
    []
  end

  def execute(*args, **params)
    # Adapter for flexible argument handling (RubyLLM vs Agents)
    tool_context, remaining_args = extract_tool_context(args)
    actual_params = resolve_params(remaining_args, params)

    # Agents::Tool#execute expects (tool_context, **params)
    super(tool_context, **actual_params.symbolize_keys)
  end

  protected

  def resolve_params(args, params)
    # RubyLLM: [params_hash], {}
    # Agents: [context], {params_hash}
    if args.first.is_a?(Hash) && params.empty?
      args.first
    else
      params
    end.with_indifferent_access
  end

  def extract_tool_context(args)
    return [nil, []] if args.empty?

    first = args.first
    if first.respond_to?(:state) || first.respond_to?(:context)
      [first, args.drop(1)]
    else
      [nil, args]
    end
  end

  def resolve_context(tool_context)
    # Handle the case where tool_context is a Hash (Agents gem / Sub-agents)
    # or an Object with a state reader (RubyLLM / Main Agent)
    if tool_context.respond_to?(:state)
      tool_context.state
    elsif tool_context.is_a?(Hash)
      tool_context
    else
      {}
    end.with_indifferent_access
  end

  private

  def account_scoped(model_class)
    model_class.where(account_id: @assistant.account_id)
  end

  def find_conversation(state)
    conversation_id = state&.dig(:conversation, :id)
    return nil unless conversation_id

    account_scoped(::Conversation).find_by(id: conversation_id)
  end

  def find_contact(state)
    contact_id = state&.dig(:contact, :id)
    return nil unless contact_id

    account_scoped(::Contact).find_by(id: contact_id)
  end

  def log_tool_usage(action, details = {})
    Rails.logger.info do
      "#{self.class.name}: #{action} for assistant #{@assistant&.id} - #{details.inspect}"
    end
  end
end
