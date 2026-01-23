class Integrations::Captain::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  private

  def get_response(_session_id, message_content)
    call_captain(message_content)
  end

  # Prevent bot from replying to itself or other agents
  def should_run_processor?(message)
    return false if message.outgoing? || message.sender_type != 'Contact'

    super
  end

  def process_response(message, response)
    if response == 'conversation_handoff'
      message.conversation.bot_handoff!
    else
      create_conversation(message, { content: response })
    end
  end

  def create_conversation(message, content_params)
    return if content_params.blank?

    conversation = message.conversation
    conversation.messages.create!(
      content_params.merge(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        }
      )
    )
  end

  def call_captain(message_content)
    url = "#{GlobalConfigService.load('CAPTAIN_API_URL',
                                      '')}/accounts/#{hook.settings['account_id']}/assistants/#{hook.settings['assistant_id']}/chat"

    headers = {
      'X-USER-EMAIL' => hook.settings['account_email'],
      'X-USER-TOKEN' => hook.settings['access_token'],
      'Content-Type' => 'application/json'
    }

    body = {
      message: message_content,
      previous_messages: previous_messages
    }

    response = HTTParty.post(url, headers: headers, body: body.to_json)
    response.parsed_response['message']
  end

  def previous_messages
    current_message_id = event_data[:message].id

    # Fetch last 20 messages before the current one
    messages = conversation.messages
                           .where(message_type: [:outgoing, :incoming])
                           .where(private: false)
                           .where(content_type: 'text')
                           .where('id < ?', current_message_id) # Exclude current message
                           .reorder(created_at: :desc) # Get latest first
                           .limit(20)

    # Reverse to chronological order and map
    messages.to_a.reverse.map do |message|
      { message: message.content, type: determine_role(message) }
    end
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'User' : 'Bot'
  end
end
