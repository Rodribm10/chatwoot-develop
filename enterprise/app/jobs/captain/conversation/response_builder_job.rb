class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  MAX_MESSAGE_LENGTH = 10_000
  retry_on ActiveStorage::FileNotFoundError, attempts: 3, wait: 2.seconds
  retry_on Faraday::BadRequestError, attempts: 3, wait: 2.seconds

  def perform(conversation, assistant)
    Rails.logger.info "ResponseBuilderJob: Starting for Conv #{conversation.id}, Assistant #{assistant.id}"
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant
    @start_time = Time.zone.now
    @response_delivered = false

    Current.executed_by = @assistant
    Current.account = conversation.account

    trigger_typing_status('on')
    trigger_media_analysis

    Rails.logger.info "[ResponseBuilderJob] Captain V2 Enabled? #{captain_v2_enabled?}"
    File.open('/tmp/v2_debug.log', 'a') { |f| f.puts "[#{Time.zone.now}] ResponseBuilderJob: V2 Enabled? #{captain_v2_enabled?}" }

    if captain_v2_enabled?
      generate_response_with_v2
    else
      ActiveRecord::Base.transaction do
        generate_and_process_response
      end
    end
  rescue StandardError => e
    trigger_typing_status('off')
    raise e if e.is_a?(ActiveStorage::FileNotFoundError) || e.is_a?(Faraday::BadRequestError)

    handle_error(e)
  end

  private

  delegate :account, :inbox, to: :@conversation

  def generate_and_process_response
    Rails.logger.info 'ResponseBuilderJob: Generating response...'
    extract_contact_identity
    faq_response = maybe_answer_from_faq
    if faq_response.present?
      @response = {
        'response' => faq_response,
        'reasoning' => 'faq_lookup_direct',
        'sentiment' => 'neutral',
        'agent_name' => @assistant.name
      }
      process_response
      Rails.logger.info 'ResponseBuilderJob: FAQ response generated and processed.'
      return
    end

    # Aggregation Logic
    new_messages = fetch_new_incoming_messages
    aggregated_text = new_messages.map { |m| prepare_message_text_content(m) }.join("\n")
    exclude_ids = new_messages.map(&:id)

    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant, conversation: @conversation).generate_response(
      additional_message: aggregated_text,
      message_history: collect_previous_messages(exclude_ids: exclude_ids)
    )
    process_response
    Rails.logger.info 'ResponseBuilderJob: Response generated and processed.'
  end

  def generate_response_with_v2
    extract_contact_identity
    faq_response = maybe_answer_from_faq
    if faq_response.present?
      @response = {
        'response' => faq_response,
        'reasoning' => 'faq_lookup_direct',
        'sentiment' => 'neutral',
        'agent_name' => @assistant.name
      }
      process_response
      return
    end

    # Aggregation Logic (V2)
    new_messages = fetch_new_incoming_messages
    aggregated_text = new_messages.map { |m| prepare_message_text_content(m) }.join("\n")
    exclude_ids = new_messages.map(&:id)

    history = collect_previous_messages(exclude_ids: exclude_ids)
    history << { role: 'user', content: aggregated_text } if aggregated_text.present?

    @response = Captain::Assistant::AgentRunnerService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: history
    )
    process_response
  end

  def process_response
    handled = if @response['handoff_trigger'].present?
                apply_handoff_behavior(@response['handoff_trigger'])
              elsif handoff_requested?
                apply_handoff_behavior('user_request')
              elsif negative_sentiment?
                apply_handoff_behavior('sentiment')
              end
    return if handled

    humanized_delay(@response['response'])
    trigger_typing_status('off')
    create_messages
    Rails.logger.info("[CAPTAIN][ResponseBuilderJob] Incrementing response usage for #{account.id}")
    account.increment_response_usage
  end

  def negative_sentiment?
    return false unless @assistant.config['handoff_on_sentiment']

    # Force handoff if user is angry or very frustrated
    %w[angry frustrated].include?(@response['sentiment']&.downcase)
  end

  def apply_handoff_behavior(trigger_key)
    action = handoff_action_for(trigger_key)
    case action
    when 'handoff'
      if handoff_allowed?
        process_action('handoff', trigger_key: trigger_key)
        return true
      else
        @response['response'] = fallback_handoff_blocked_message
        @response['agent_name'] ||= @assistant.name
      end
    when 'reply'
      @response['response'] = handoff_message_for(trigger_key)
      @response['agent_name'] ||= @assistant.name
    when 'ignore'
      return unless @response['response'].to_s.strip == 'conversation_handoff'

      @response['response'] = fallback_handoff_blocked_message
      @response['agent_name'] ||= @assistant.name
    end

    false
  end

  def handoff_action_for(trigger_key)
    config = @assistant.config || {}
    key = case trigger_key.to_s
          when 'tool_failure' then 'handoff_on_tool_failure_action'
          when 'llm_error' then 'handoff_on_llm_error_action'
          when 'sentiment' then 'handoff_on_sentiment_action'
          when 'user_request' then 'handoff_on_user_request_action'
          end

    action = key ? config[key].to_s : ''
    action = action.presence || default_handoff_action(trigger_key)
    %w[handoff reply ignore].include?(action) ? action : default_handoff_action(trigger_key)
  end

  def default_handoff_action(trigger_key)
    return 'handoff' if %w[llm_error user_request sentiment].include?(trigger_key.to_s)

    'ignore'
  end

  def handoff_message_for(trigger_key)
    config = @assistant.config || {}
    key = case trigger_key.to_s
          when 'tool_failure' then 'handoff_on_tool_failure_message'
          when 'llm_error' then 'handoff_on_llm_error_message'
          when 'sentiment' then 'handoff_on_sentiment_message'
          when 'user_request' then 'handoff_on_user_request_message'
          end

    message = key ? config[key].to_s.strip : ''
    return message if message.present?

    I18n.t('captain.handoff_default_message',
           default: 'Desculpe, estou com dificuldades tecnicas no momento. Por favor, tente novamente em alguns instantes.')
  end

  def handoff_allowed?
    value = @assistant.config['allow_handoff']
    return true if value.nil?

    value == true || value.to_s == 'true'
  end

  def trigger_typing_status(status)
    Conversations::TypingStatusManager.new(
      @conversation,
      @assistant,
      { typing_status: status, is_private: false }
    ).toggle_typing_status
  rescue StandardError => e
    Rails.logger.warn "Failed to trigger typing status: #{e.message}"
  end

  def humanized_delay(response_text)
    return if response_text.blank?

    # Roughly 50ms per character simulation
    typing_speed = 50
    target_delay = (response_text.length * typing_speed) / 1000.0

    # Cap at 7 seconds to balance humanization vs speed
    target_delay = [target_delay, 7.0].min

    elapsed_time = Time.zone.now - @start_time
    remaining_delay = target_delay - elapsed_time

    sleep(remaining_delay) if remaining_delay.positive?
  end

  def fetch_new_incoming_messages
    # Fetch all messages ordered by creation
    all_messages = @conversation.messages.order(:created_at)

    # Find the last message sent by the assistant (outgoing)
    last_outgoing_index = all_messages.rindex(&:outgoing?)

    potential_messages = if last_outgoing_index
                           # Get all messages after the last outgoing one
                           all_messages[(last_outgoing_index + 1)..] || []
                         else
                           # If no outgoing messages, use all messages
                           all_messages
                         end

    # Filter for valid incoming messages (not private, incoming type)
    potential_messages.select { |m| m.incoming? && !m.private? }
  end

  def collect_previous_messages(exclude_ids: [])
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .where.not(id: exclude_ids)
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

  def maybe_answer_from_faq
    return nil unless @assistant.config['feature_faq']

    last_message = ::Message
                   .where(conversation_id: @conversation.id, message_type: :incoming, private: false)
                   .order(created_at: :desc)
                   .first
    return nil if last_message.blank?

    query = last_message.content.to_s.strip
    return nil unless faq_question_like?(query)

    Rails.logger.info("[CAPTAIN][FAQ] Forcing FAQ lookup for query: #{query.inspect}")

    tool = Captain::Tools::FaqLookupTool.new(@assistant, conversation: @conversation, user: @conversation.contact)
    result = tool.perform({ conversation: { id: @conversation.id }, last_user_message: query }, { query: query })
    return nil if result.to_s.match?(/No relevant FAQs found/i)

    extract_faq_answer(result)
  rescue StandardError => e
    Rails.logger.warn("[CAPTAIN][FAQ] Prelookup failed: #{e.message}")
    nil
  end

  def extract_faq_answer(result)
    return nil if result.blank?

    # 1. Tenta extrair usando o padrão 'Answer: '
    match = result.to_s.match(/Answer:\s*(.+)$/m)
    return match[1].to_s.strip if match.present? && match[1].present?

    # 2. Fallback: Se não tem o marcador, usa o texto todo se não for uma mensagem de erro
    clean_text = result.to_s.strip
    return nil if clean_text.match?(/No relevant FAQs found/i)

    clean_text.presence
  end

  def faq_question_like?(query)
    normalized = query.to_s.downcase.strip
    return false if normalized.blank?

    greeting = normalized.gsub(/[^a-z0-9]/, '')
    return false if %w[oi ola bomdia boatarde boanoite].include?(greeting)

    normalized.match?(/\?|qual|quanto|valor|preco|preço|como|onde|horario|hora|cardapio|cardápio/)
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end

  def prepare_message_text_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_text_content
  end

  def handoff_requested?
    @response['response'] == 'conversation_handoff'
  end

  def fallback_handoff_blocked_message
    I18n.t('conversations.captain.error',
           default: 'Desculpe, estou com dificuldades técnicas no momento. Por favor, tente novamente em alguns instantes.')
  end

  def process_action(action, trigger_key: nil)
    case action
    when 'handoff'
      I18n.with_locale(@assistant.account.locale) do
        create_handoff_message
        # @conversation.bot_handoff!
        # [FIX] Use manual handoff with 'pausar_ia' to avoid Automation Rule loop
        @conversation.open!
        @conversation.account.labels.find_or_create_by!(title: 'pausar_ia') do |label|
          label.description = 'Pausa a IA e evita loops de regras externas'
          label.color = '#f59e0b'
          label.show_on_sidebar = true
        end
        @conversation.add_labels(['pausar_ia'])
        @conversation.save!
        apply_handoff_side_effects
        handle_sentiment_handoff_alerts if trigger_key.to_s == 'sentiment'
        deliver_handoff_webhook
        log_handoff_event
        send_out_of_office_message_if_applicable
      end
    end
  end

  def send_out_of_office_message_if_applicable
    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(@conversation)
  end

  def handle_sentiment_handoff_alerts
    trigger_excerpt = last_incoming_message_excerpt
    summary = build_handoff_summary

    create_private_note_for_handoff(trigger_excerpt, summary)
    send_leader_whatsapp_alert(trigger_excerpt, summary)
  end

  def last_incoming_message_excerpt
    message = @conversation.messages.where(message_type: :incoming, private: false).order(created_at: :desc).first
    message&.content.to_s.strip[0, 400]
  end

  def build_handoff_summary
    summary = @conversation.latest_crm_insight&.summary_text.to_s.strip
    summary = build_conversation_summary if summary.blank?
    summary.to_s.strip[0, 400]
  end

  def create_private_note_for_handoff(trigger_excerpt, summary)
    return if trigger_excerpt.blank? && summary.blank?

    note_parts = []
    note_parts << 'Handoff automatico por sentimento negativo.'
    note_parts << "Resumo: #{summary}" if summary.present?
    note_parts << "Trecho: \"#{trigger_excerpt}\"" if trigger_excerpt.present?
    content = note_parts.join("\n")

    @conversation.messages.create!(
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: inbox.id,
      sender: @assistant,
      content: content,
      private: true
    )
  end

  def send_leader_whatsapp_alert(trigger_excerpt, summary)
    unit = resolve_unit_for_conversation
    return if unit.blank?

    leader_phone = unit.leader_whatsapp.to_s.gsub(/[^\d]/, '')
    return if leader_phone.blank?
    return if unit.inbox.blank?

    contact_inbox = ContactInboxWithContactBuilder.new(
      inbox: unit.inbox,
      contact_attributes: {
        name: "Lider #{unit.name}",
        phone_number: leader_phone
      },
      source_id: leader_phone
    ).perform

    leader_conversation = contact_inbox.conversations.order(created_at: :desc).first
    leader_conversation ||= Conversation.create!(
      account_id: unit.inbox.account_id,
      inbox_id: unit.inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      status: :open
    )

    message_text = build_leader_alert_message(unit.name, summary, trigger_excerpt)
    leader_conversation.messages.create!(
      message_type: :outgoing,
      account_id: unit.inbox.account_id,
      inbox_id: unit.inbox.id,
      sender: @assistant,
      content: message_text
    )
  rescue StandardError => e
    Rails.logger.warn "[CAPTAIN][handoff] Failed to alert leader: #{e.message}"
  end

  def resolve_unit_for_conversation
    CaptainInbox.find_by(inbox_id: inbox.id, captain_assistant_id: @assistant.id)&.unit ||
      Captain::Unit.find_by(inbox_id: inbox.id)
  end

  def build_leader_alert_message(unit_name, summary, trigger_excerpt)
    link = conversation_link
    parts = []
    parts << "ALERTA: cliente irritado - Unidade #{unit_name}"
    parts << 'O cliente precisa ser atendido para nao termos maiores problemas.'
    parts << 'Valor: obsessao pelo cliente.'
    parts << "Resumo: #{summary}" if summary.present?
    parts << "Trecho: \"#{trigger_excerpt}\"" if trigger_excerpt.present?
    parts << "Link da conversa: #{link}" if link.present?
    parts.join("\n")
  end

  def conversation_link
    base_url = ENV.fetch('FRONTEND_URL', '').to_s
    base_url = base_url.gsub('0.0.0.0', '127.0.0.1')
    return '' if base_url.blank?

    "#{base_url}/app/accounts/#{account.id}/conversations/#{@conversation.id}"
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
    @response_delivered = true
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

  def deliver_handoff_webhook
    handoff_context = {
      trigger: determine_handoff_trigger,
      sentiment: @response['sentiment'],
      reason: @response['reasoning'],
      last_message: @conversation.messages.incoming.last&.content,
      conversation_summary: build_conversation_summary
    }

    Captain::HandoffWebhookService.new(
      conversation: @conversation,
      assistant: @assistant,
      handoff_context: handoff_context
    ).deliver
  end

  def determine_handoff_trigger
    return 'sentiment' if negative_sentiment?
    return 'error' if @response&.dig('error').present?

    'ai_decision'
  end

  def build_conversation_summary
    # Use existing CRM insight summary if available
    @conversation.latest_crm_insight&.summary_text ||
      # Otherwise, concatenate last 5 messages
      @conversation.messages.where(private: false).last(5).map(&:content).join(' | ')
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
    return true if @response_delivered

    @response ||= {
      'response' => fallback_handoff_blocked_message,
      'sentiment' => 'neutral',
      'agent_name' => @assistant.name
    }

    handled = apply_handoff_behavior('llm_error')
    create_messages unless handled
    true
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end

  def trigger_media_analysis
    # Inspect ALL new incoming messages, as user might send Image + Text in quick succession
    new_messages = fetch_new_incoming_messages
    return if new_messages.blank?

    new_messages.each do |msg|
      next if msg.attachments.blank?

      Rails.logger.info "[ResponseBuilderJob] Triggering Jasmine Media Analysis for Message #{msg.id}"
      Jasmine::MediaAnalyzerService.new(message: msg).perform
      msg.attachments.reload
    end
  rescue StandardError => e
    Rails.logger.error "[ResponseBuilderJob] Media analysis failed: #{e.message}"
  end

  def captain_v2_enabled?
    account.feature_enabled?('captain_integration_v2')
  end
end
