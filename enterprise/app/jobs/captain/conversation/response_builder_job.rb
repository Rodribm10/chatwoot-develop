class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  MAX_MESSAGE_LENGTH = 10_000
  retry_on ActiveStorage::FileNotFoundError, attempts: 3, wait: 2.seconds
  retry_on Faraday::BadRequestError, attempts: 3, wait: 2.seconds

  def perform(conversation, assistant)
    Rails.logger.info "ResponseBuilderJob: Starting for Conv #{conversation.id}, Assistant #{assistant.id}"
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant

    Current.executed_by = @assistant
    Current.account = conversation.account

    if captain_v2_enabled?
      generate_response_with_v2
    else
      ActiveRecord::Base.transaction do
        generate_and_process_response
      end
    end
  rescue StandardError => e
    raise e if e.is_a?(ActiveStorage::FileNotFoundError) || e.is_a?(Faraday::BadRequestError)

    handle_error(e)
  end

  private

  delegate :account, :inbox, to: :@conversation

  def generate_and_process_response
    Rails.logger.info 'ResponseBuilderJob: Generating response...'
    extract_contact_identity
    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: collect_previous_messages
    )
    process_response
    Rails.logger.info 'ResponseBuilderJob: Response generated and processed.'
  end

  def generate_response_with_v2
    extract_contact_identity
    @response = Captain::Assistant::AgentRunnerService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: collect_previous_messages
    )
    process_response
  end

  def process_response
    return process_action('handoff') if handoff_requested?

    create_messages
    Rails.logger.info("[CAPTAIN][ResponseBuilderJob] Incrementing response usage for #{account.id}")
    account.increment_response_usage
  end

  def collect_previous_messages
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .map do |message|
      message_hash = {
        content: prepare_multimodal_message_content(message),
        role: determine_role(message)
      }

      # Include agent_name if present in additional_attributes
      message_hash[:agent_name] = message.additional_attributes['agent_name'] if message.additional_attributes&.dig('agent_name').present?

      message_hash
    end
  end

  def extract_contact_identity
    last_message = @conversation.messages
                                .where(message_type: :incoming, private: false)
                                .order(created_at: :desc)
                                .first
    return if last_message.blank?

    Captain::Llm::ContactIdentityService.new(
      contact: @conversation.contact,
      message_content: last_message.content
    ).extract_and_update
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end

  def handoff_requested?
    @response['response'] == 'conversation_handoff'
  end

  def process_action(action)
    case action
    when 'handoff'
      I18n.with_locale(@assistant.account.locale) do
        create_handoff_message
        @conversation.bot_handoff!
        apply_handoff_side_effects
        log_handoff_event
        send_out_of_office_message_if_applicable
      end
    end
  end

  def send_out_of_office_message_if_applicable
    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(@conversation)
  end

  def create_handoff_message
    create_outgoing_message(
      @assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff')
    )
  end

  def create_messages
    response_text = inject_preferred_name(@response['response'])
    response_text = prevent_fake_handoff(response_text)
    validate_message_content!(response_text)
    create_outgoing_message(response_text, agent_name: @response['agent_name'])
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content, agent_name: nil)
    additional_attrs = {}
    additional_attrs[:agent_name] = agent_name if agent_name.present?

    @conversation.messages.create!(
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: inbox.id,
      sender: @assistant,
      content: message_content,
      additional_attributes: additional_attrs
    )
  end

  def inject_preferred_name(content)
    return content if content.blank?

    attributes = @conversation.contact&.additional_attributes || {}
    preferred_name = attributes['preferred_name'].to_s.strip
    confidence = attributes['name_confidence'].to_f
    return content if preferred_name.blank? || confidence < 0.8
    return content if content.downcase.include?(preferred_name.downcase)

    "#{preferred_name}, #{content}"
  end

  def prevent_fake_handoff(content)
    return content if content.blank? || handoff_requested?

    handoff_message = @assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff')
    return content unless content.strip == handoff_message.to_s.strip

    fallback_question
  end

  def fallback_question
    'Pode me dizer sua duvida de forma mais especifica?'
  end

  def apply_handoff_side_effects
    @conversation.add_labels(['handoff_requested'])

    return if @conversation.assignee.present?

    allowed_agent_ids = @conversation.inbox.member_ids_with_assignment_capacity
    AutoAssignment::AgentAssignmentService.new(conversation: @conversation, allowed_agent_ids: allowed_agent_ids).perform
  end

  def log_handoff_event
    Rails.logger.info(
      "[CAPTAIN][handoff] request_id=#{extract_request_id} conversation_id=#{@conversation.id} assistant_id=#{@assistant.id} " \
      "assignee_id=#{@conversation.assignee_id} team_id=#{@conversation.team_id}"
    )
  end

  def extract_request_id
    return RequestStore.store[:request_id] if defined?(RequestStore) && RequestStore.store[:request_id].present?

    Thread.current[:request_id] || 'unknown'
  end

  def handle_error(error)
    log_error(error)
    process_action('handoff')
    true
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end

  def captain_v2_enabled?
    account.feature_enabled?('captain_integration_v2')
  end
end
