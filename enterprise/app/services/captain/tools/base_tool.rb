class Captain::Tools::BaseTool < RubyLLM::Tool
  attr_accessor :assistant, :conversation

  FALLBACK_EXCLUDED_TOOL_KEYS = %w[faq_lookup react_to_message].freeze

  def initialize(assistant, user: nil, conversation: nil)
    @assistant = assistant
    @user = user
    @conversation = conversation
    super()
  end

  def call(args)
    RubyLLM.logger.debug "Tool #{name} called with: #{args.inspect}"
    result = execute(**args.transform_keys(&:to_sym))
    RubyLLM.logger.debug "Tool #{name} returned: #{result.inspect}"

    return result if result.is_a?(RubyLLM::Tool::Halt)
    return result unless fallback_message.present?
    return result unless errorish_result?(result)

    fallback_message
  rescue StandardError => e
    fallback = fallback_message
    return fallback if fallback.present?

    raise e
  end

  def execute(*args, **params)
    # Default implementation to be overridden
  end

  def parameters
    schema = respond_to?(:tool_parameters_schema) ? tool_parameters_schema : nil
    return build_parameters_from_schema(schema) if schema.is_a?(Hash) && schema[:properties].present?

    super
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

  def build_parameters_from_schema(schema)
    required = Array(schema[:required]).map(&:to_s)

    schema[:properties].each_with_object({}) do |(name, spec), acc|
      spec = spec.with_indifferent_access
      acc[name.to_s] = RubyLLM::Parameter.new(
        name.to_s,
        type: spec[:type] || 'string',
        desc: spec[:description],
        required: required.include?(name.to_s)
      )
    end
  end

  def fallback_message
    return nil if FALLBACK_EXCLUDED_TOOL_KEYS.include?(name)
    return nil unless @assistant&.account_id && @assistant&.id

    config = Captain::ToolConfig.find_by(
      account_id: @assistant.account_id,
      captain_assistant_id: @assistant.id,
      tool_key: name
    )
    config&.fallback_message.presence
  end

  def errorish_result?(result)
    return false unless result.is_a?(String)

    text = result.strip.downcase
    text.start_with?('erro', 'erro:', 'system info', 'falha', 'failure')
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
