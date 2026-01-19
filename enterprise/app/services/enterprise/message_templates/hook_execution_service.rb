module Enterprise::MessageTemplates::HookExecutionService
  MAX_ATTACHMENT_WAIT_SECONDS = 4

  def trigger_templates
    super
    return unless should_process_captain_response?
    return perform_handoff unless inbox.captain_active?

    schedule_captain_response
  end

  def should_send_greeting?
    return false if captain_handling_conversation?

    super
  end

  def should_send_out_of_office_message?
    return false if captain_handling_conversation?

    super
  end

  def should_send_email_collect?
    return false if captain_handling_conversation?

    super
  end

  private

  def schedule_captain_response
    # [FEATURE] Send 'composing' state immediately to indicate AI is processing
    send_typing_indicator if inbox.channel_type == 'Channel::Whatsapp'

    debounce_delay = 15.seconds
    timestamp = Time.current.to_f
    Redis::Alfred.set(debounce_key, timestamp, ex: 1.hour)

    Captain::Conversation::DebounceResponseJob.set(wait: debounce_delay).perform_later(
      conversation.id,
      conversation.inbox.captain_assistant.id,
      timestamp
    )
  end

  def send_typing_indicator
    # Access phone number safely via contact association
    phone = conversation.contact&.phone_number
    return unless phone.present?

    # Assuming Wuzapi is the provider for Channel::Whatsapp in this context
    # We need to find the Wuzapi client instance or create one.
    # Typically this is handled by the channel or provider service.

    # Wrap everything in a rescue block to ensure we NEVER block the main flow
    begin
      channel = inbox.channel
      # Safe navigation for provider_config
      return unless channel&.provider_config&.dig('provider') == 'wuzapi'

      token = channel.wuzapi_user_token
      url = channel.provider_config['wuzapi_base_url']

      return unless token.present? && url.present?

      client = Wuzapi::Client.new(url)

      # Wuzapi usually requires clean numbers; Channel::Whatsapp logic cleans it.
      # Let's clean it here too to be safe, matching WuzapiService logic:
      normalized_phone = phone.gsub(/[\+\s\-\(\)]/, '')

      client.send_chat_presence(token, normalized_phone, 'composing')
    rescue StandardError => e
      Rails.logger.warn "[HookExecutionService] Failed to send typing indicator: #{e.message}"
    end
  end

  def debounce_key
    "captain:debounce:conversation:#{conversation.id}"
  end

  def calculate_attachment_wait_time
    attachment_count = message.attachments.size
    base_wait = 1.second

    # Wait longer for more attachments or larger files
    additional_wait = [attachment_count * 1, MAX_ATTACHMENT_WAIT_SECONDS].min.seconds
    base_wait + additional_wait
  end

  def should_process_captain_response?
    # Regra do Usuário: "Não responder APENAS se estiver atribuído E tiver a etiqueta na CONVERSA"

    is_assigned_to_human = conversation.assignee.present? && !conversation.assignee.is_a?(AgentBot)

    # [FIX] Removido verificação de labels do contato. Agora olha apenas para a conversa.
    # [FIX] Adicionado 'pausar_ia' como alternativa para evitar loop de automação externa.
    has_disable_label = conversation.labels.pluck(:name).intersect?(%w[desligar_ia pausar_ia])

    if is_assigned_to_human || has_disable_label
      Rails.logger.info "[HookExecutionService] Skipping AI. Assigned: #{is_assigned_to_human}, Disabled Label: #{has_disable_label} (Label 'desligar_ia'/'pausar_ia' found)"
      return false
    end

    # Se estiver atribuído a um humano, geralmente não queremos que a IA interfira A MENOS que o usuário queira.
    # Como o usuário disse "responda igual no playground", vou permitir enquanto não houver o combo (Assigned + Label).

    should_process = message.incoming? && inbox.captain_assistant.present?

    unless should_process
      Rails.logger.info "[HookExecutionService] Skipping AI. Incoming: #{message.incoming?}, Assistant Present: #{inbox.captain_assistant.present?}"
    end

    should_process
  end

  def perform_handoff
    return unless conversation.pending?

    Rails.logger.info("Captain limit exceeded, performing handoff mid-conversation for conversation: #{conversation.id}")
    conversation.messages.create!(
      message_type: :outgoing,
      account_id: conversation.account.id,
      inbox_id: conversation.inbox.id,
      content: 'Transferring to another agent for further assistance.'
    )
    conversation.bot_handoff!
    send_out_of_office_message_after_handoff
  end

  def send_out_of_office_message_after_handoff
    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(conversation)
  end

  def captain_handling_conversation?
    conversation.pending? && inbox.respond_to?(:captain_assistant) && inbox.captain_assistant.present?
  end
end
