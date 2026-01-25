class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    # CRITICAL: Remove RawMessage IMMEDIATELY to prevent Rails logging from serializing binary data
    params[:event]&.delete('RawMessage')
    params.dig(:event, 'Message')&.delete('RawMessage')

    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    perform_whatsapp_events_job
  end

  private

  def perform_whatsapp_events_job
    perform_sync if params[:awaitResponse].present?
    return if performed?

    Webhooks::WhatsappEventsJob.perform_later(sanitize_payload_for_sidekiq)
    head :ok
  end

  def perform_sync
    Webhooks::WhatsappEventsJob.perform_now(sanitize_payload_for_sidekiq)
  rescue Whatsapp::IncomingMessageBaileysService::InvalidWebhookVerifyToken
    head :unauthorized
  rescue Whatsapp::IncomingMessageBaileysService::MessageNotFoundError
    head :not_found
  end

  # WHITELIST approach: Build a clean payload with ONLY allowed fields
  # This prevents ANY binary data from leaking into JSON serialization
  def sanitize_payload_for_sidekiq
    raw = params.to_unsafe_hash
    clean_payload = build_base_payload(raw)

    clean_payload['event'] = build_clean_event(raw['event']) if raw['event'].is_a?(Hash)

    if raw['whatsapp'].is_a?(Hash)
      clean_payload['whatsapp'] = { 'event' => clean_payload['event'] }.merge(
        raw['whatsapp'].slice('type', 'state', 'instanceName', 'userID')
      )
    end

    Rails.logger.info 'WuzAPI: Payload sanitized (WHITELIST mode)'
    deep_force_utf8(clean_payload)
  end

  def build_base_payload(raw)
    {
      'type' => raw['type'],
      'state' => raw['state'],
      'instanceName' => raw['instanceName'],
      'userID' => raw['userID'],
      'controller' => raw['controller'],
      'action' => raw['action'],
      'phone_number' => raw['phone_number']
    }
  end

  def build_clean_event(raw_event)
    clean_event = {}

    if raw_event['Info'].is_a?(Hash)
      clean_event['Info'] = raw_event['Info'].slice(
        'ID', 'Type', 'MediaType', 'Chat', 'Sender', 'SenderAlt', 'RecipientAlt', 'IsFromMe', 'IsGroup',
        'Timestamp', 'PushName', 'MessageSource'
      )
    end

    # Safe event metadata
    %w[Chat Sender IsFromMe IsGroup Timestamp AddressingMode BroadcastListOwner
       BroadcastRecipients RecipientAlt SenderAlt MessageIDs MessageSender].each do |key|
      clean_event[key] = raw_event[key] if raw_event.key?(key)
    end

    if raw_event['Message'].is_a?(Hash)
      clean_msg = build_clean_message(raw_event['Message'])
      clean_event['Message'] = clean_msg unless clean_msg.empty?
    end

    clean_event
  end

  def build_clean_message(msg)
    clean_msg = {}
    clean_msg['conversation'] = msg['conversation'] if msg['conversation'].is_a?(String)

    clean_msg.merge!(clean_extended_text_message(msg['extendedTextMessage']))
    clean_msg.merge!(clean_media_message(msg, 'imageMessage'))
    clean_msg.merge!(clean_media_message(msg, 'videoMessage'))
    clean_msg.merge!(clean_media_message(msg, 'audioMessage'))
    clean_msg.merge!(clean_document_message(msg['documentMessage']))

    clean_msg
  end

  def clean_extended_text_message(ext_msg)
    return {} unless ext_msg.is_a?(Hash)

    result = { 'extendedTextMessage' => { 'text' => ext_msg['text'] } }

    result['extendedTextMessage']['contextInfo'] = clean_context_info(ext_msg['contextInfo']) if ext_msg['contextInfo'].is_a?(Hash)

    result
  end

  def clean_context_info(ctx)
    {
      'stanzaID' => ctx['stanzaID'] || ctx['stanzaId'],
      'participant' => ctx['participant']
    }.compact
  end

  def clean_media_message(msg, type)
    media = msg[type]
    return {} unless media.is_a?(Hash)

    clean_data = {
      'URL' => media['URL'] || media['url'],
      'directPath' => media['directPath'],
      'mediaKey' => media['mediaKey'],
      'fileEncSha256' => media['fileEncSha256'] || media['fileEncSHA256'],
      'fileSha256' => media['fileSha256'] || media['fileSHA256'],
      'fileLength' => media['fileLength'],
      'mimetype' => media['mimetype'],
      'seconds' => media['seconds'],
      'caption' => media['caption'],
      'ptt' => media['ptt'],
      'width' => media['width'],
      'height' => media['height']
    }

    clean_data['contextInfo'] = clean_context_info(media['contextInfo']) if media['contextInfo'].is_a?(Hash)

    { type => clean_data.compact }
  end

  def clean_document_message(doc)
    return {} unless doc.is_a?(Hash)

    {
      'documentMessage' => {
        'URL' => doc['URL'] || doc['url'],
        'directPath' => doc['directPath'],
        'mediaKey' => doc['mediaKey'],
        'fileEncSha256' => doc['fileEncSha256'] || doc['fileEncSHA256'],
        'fileSha256' => doc['fileSha256'] || doc['fileSHA256'],
        'fileLength' => doc['fileLength'],
        'mimetype' => doc['mimetype'],
        'fileName' => doc['fileName'],
        'title' => doc['title']
      }.compact
    }
  end

  def deep_force_utf8(obj)
    case obj
    when String
      (obj.frozen? ? obj.dup : obj).force_encoding('UTF-8')
                                   .encode('UTF-8', invalid: :replace, undef: :replace)
    when Hash
      obj.transform_values { |v| deep_force_utf8(v) }
    when Array
      obj.map { |v| deep_force_utf8(v) }
    else
      obj
    end
  end

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def inactive_whatsapp_number?
    phone_number = params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end
end
