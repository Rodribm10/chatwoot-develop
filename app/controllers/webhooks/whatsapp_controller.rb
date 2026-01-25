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

    # Build a completely NEW payload with only safe fields
    clean_payload = {
      'type' => raw['type'],
      'state' => raw['state'],
      'instanceName' => raw['instanceName'],
      'userID' => raw['userID'],
      'controller' => raw['controller'],
      'action' => raw['action'],
      'phone_number' => raw['phone_number']
    }

    # Only copy safe event fields
    if raw['event'].is_a?(Hash)
      clean_event = {}

      # Info fields (all safe strings/ids)
      if raw['event']['Info'].is_a?(Hash)
        clean_event['Info'] = raw['event']['Info'].slice(
          'ID', 'Type', 'MediaType', 'Chat', 'Sender', 'SenderAlt', 'RecipientAlt', 'IsFromMe', 'IsGroup',
          'Timestamp', 'PushName', 'MessageSource'
        )
      end

      # Safe event metadata
      %w[Chat Sender IsFromMe IsGroup Timestamp AddressingMode BroadcastListOwner
         BroadcastRecipients RecipientAlt SenderAlt MessageIDs MessageSender].each do |key|
        clean_event[key] = raw['event'][key] if raw['event'].key?(key)
      end

      # Message content - WHITELIST only safe fields
      if raw['event']['Message'].is_a?(Hash)
        msg = raw['event']['Message']
        clean_msg = {}

        # Text messages
        clean_msg['conversation'] = msg['conversation'] if msg['conversation'].is_a?(String)

        if msg['extendedTextMessage'].is_a?(Hash)
          clean_msg['extendedTextMessage'] = {
            'text' => msg['extendedTextMessage']['text']
          }
          # Only copy contextInfo if it doesn't have quotedMessage with binaries
          # Only copy contextInfo if it doesn't have quotedMessage with binaries
          if msg['extendedTextMessage']['contextInfo'].is_a?(Hash)
            ctx = msg['extendedTextMessage']['contextInfo']
            clean_msg['extendedTextMessage']['contextInfo'] = {
              'stanzaID' => ctx['stanzaID'] || ctx['stanzaId'],
              'participant' => ctx['participant']
            }.compact
          end
        end

        # Image messages - ONLY safe metadata, NO binaries
        if msg['imageMessage'].is_a?(Hash)
          img = msg['imageMessage']
          clean_msg['imageMessage'] = {
            'URL' => img['URL'] || img['url'],
            'directPath' => img['directPath'],
            'mediaKey' => img['mediaKey'],
            'fileEncSha256' => img['fileEncSha256'] || img['fileEncSHA256'],
            'fileSha256' => img['fileSha256'] || img['fileSHA256'],
            'fileLength' => img['fileLength'],
            'mimetype' => img['mimetype'],
            'width' => img['width'],
            'height' => img['height'],
            'caption' => img['caption'],
            'contextInfo' => {
              'stanzaID' => img.dig('contextInfo', 'stanzaID') || img.dig('contextInfo', 'stanzaId'),
              'participant' => img.dig('contextInfo', 'participant')
            }.compact
          }.compact
          # EXPLICITLY NO: JPEGThumbnail, scansSidecar, firstScanSidecar, etc
        end

        # Video messages - ONLY safe metadata
        if msg['videoMessage'].is_a?(Hash)
          vid = msg['videoMessage']
          clean_msg['videoMessage'] = {
            'URL' => vid['URL'] || vid['url'],
            'directPath' => vid['directPath'],
            'mediaKey' => vid['mediaKey'],
            'fileEncSha256' => vid['fileEncSha256'] || vid['fileEncSHA256'],
            'fileSha256' => vid['fileSha256'] || vid['fileSHA256'],
            'fileLength' => vid['fileLength'],
            'mimetype' => vid['mimetype'],
            'seconds' => vid['seconds'],
            'caption' => vid['caption'],
            'contextInfo' => {
              'stanzaID' => vid.dig('contextInfo', 'stanzaID') || vid.dig('contextInfo', 'stanzaId'),
              'participant' => vid.dig('contextInfo', 'participant')
            }.compact
          }.compact
        end

        # Audio messages
        if msg['audioMessage'].is_a?(Hash)
          aud = msg['audioMessage']
          clean_msg['audioMessage'] = {
            'URL' => aud['URL'] || aud['url'],
            'directPath' => aud['directPath'],
            'mediaKey' => aud['mediaKey'],
            'fileEncSha256' => aud['fileEncSha256'] || aud['fileEncSHA256'],
            'fileSha256' => aud['fileSha256'] || aud['fileSHA256'],
            'fileLength' => aud['fileLength'],
            'mimetype' => aud['mimetype'],
            'seconds' => aud['seconds'],
            'ptt' => aud['ptt'],
            'contextInfo' => {
              'stanzaID' => aud.dig('contextInfo', 'stanzaID') || aud.dig('contextInfo', 'stanzaId'),
              'participant' => aud.dig('contextInfo', 'participant')
            }.compact
          }.compact
        end

        # Document messages
        if msg['documentMessage'].is_a?(Hash)
          doc = msg['documentMessage']
          clean_msg['documentMessage'] = {
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
        end

        clean_event['Message'] = clean_msg unless clean_msg.empty?
      end

      clean_payload['event'] = clean_event
    end

    # Also copy whatsapp key if present (but sanitize it too)
    if raw['whatsapp'].is_a?(Hash)
      # Just reference the same clean event structure
      clean_payload['whatsapp'] = { 'event' => clean_payload['event'] }.merge(
        raw['whatsapp'].slice('type', 'state', 'instanceName', 'userID')
      )
    end

    Rails.logger.info 'WuzAPI: Payload sanitized (WHITELIST mode)'
    deep_force_utf8(clean_payload)
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
