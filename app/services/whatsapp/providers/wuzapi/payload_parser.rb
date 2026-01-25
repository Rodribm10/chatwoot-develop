class Whatsapp::Providers::Wuzapi::PayloadParser
  attr_reader :params

  def initialize(params)
    @params = params.with_indifferent_access
  end

  def external_id
    params.dig(:event, :Info, :ID)
  end

  def from_me?
    is_api_from_me = params.dig(:event, :Info, :IsFromMe) || params.dig(:event, :IsFromMe)
    return false unless is_api_from_me

    instance_phone = params['phone_number']
    sender_jid = params.dig(:event, :Info, :Sender) || params.dig(:event, :Sender)

    if instance_phone.present? && sender_jid.present?
      sender_phone = sender_jid.split('@').first
      return false if sender_phone != instance_phone
    end

    true
  end

  def message_type
    return :chat_presence if params['type'] == 'ChatPresence'

    # Info: Type contains the general classification (text, image, etc)
    type = params.dig(:event, :Info, :Type)
    media_type = params.dig(:event, :Info, :MediaType)

    # WuzAPI sometimes sends 'media' in Type and the actual type in MediaType
    type = media_type if type == 'media' && media_type.present?

    case type
    when 'text' then :text
    when 'image' then :image
    when 'audio' then :audio
    when 'video' then :video
    when 'document' then :document
    when 'sticker' then :sticker
    when 'ReadReceipt' then :ignore
    else
      # Fallback: Detect type from Message content keys
      msg = params.dig(:event, :Message)
      if msg.is_a?(Hash)
        return :text if msg[:conversation].present? || msg[:extendedTextMessage].present?
        return :image if msg[:imageMessage].present?
        return :audio if msg[:audioMessage].present?
        return :video if msg[:videoMessage].present?
        return :document if msg[:documentMessage].present?
        return :sticker if msg[:stickerMessage].present?
      end
      :unknown
    end
  end

  def presence_state
    params.dig(:event, :State)
  end

  def in_reply_to_external_id
    msg = unwrap_ephemeral_message(params.dig(:event, :Message))
    return nil unless msg.is_a?(Hash)

    # DEBUG: Log the message structure to understand reply context
    Rails.logger.info "WuzAPI Reply Debug: Message keys = #{msg.keys.inspect}"

    # 1. Extended text
    ctx = msg.dig(:extendedTextMessage, :contextInfo)
    if ctx.present?
      Rails.logger.info "WuzAPI Reply Debug: Found extendedTextMessage contextInfo = #{ctx.inspect}"
      stanza = ctx[:stanzaID] || ctx[:stanzaId]
      return stanza if stanza.present?
    end

    # 2. Media Types direct contextInfo
    [:imageMessage, :videoMessage, :audioMessage, :stickerMessage, :documentMessage].each do |key|
      ctx = msg.dig(key, :contextInfo)
      next if ctx.blank?

      Rails.logger.info "WuzAPI Reply Debug: Found #{key} contextInfo = #{ctx.inspect}"
      stanza = ctx[:stanzaID] || ctx[:stanzaId]
      return stanza if stanza.present?
    end

    # 3. Document With Caption
    if msg.key?(:documentWithCaptionMessage)
      ctx = msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :contextInfo)
      if ctx.present?
        Rails.logger.info "WuzAPI Reply Debug: Found documentWithCaptionMessage contextInfo = #{ctx.inspect}"
        return ctx[:stanzaID] || ctx[:stanzaId]
      end
    end

    # 4. Check for simple conversation with contextInfo (text reply without extendedTextMessage)
    if msg[:conversation].present? && msg[:contextInfo].present?
      ctx = msg[:contextInfo]
      Rails.logger.info "WuzAPI Reply Debug: Found conversation contextInfo = #{ctx.inspect}"
      stanza = ctx[:stanzaID] || ctx[:stanzaId]
      return stanza if stanza.present?
    end

    Rails.logger.info 'WuzAPI Reply Debug: No reply context found'
    nil
  end

  def text_content
    msg = unwrap_ephemeral_message(params.dig(:event, :Message))
    return nil unless msg.is_a?(Hash)

    # 1. Simple text
    return msg[:conversation] if msg[:conversation].present?

    # 2. Extended Text
    return msg.dig(:extendedTextMessage, :text) if msg.dig(:extendedTextMessage, :text).present?

    # 3. Media Captions (Image, Video, Document)
    [:imageMessage, :videoMessage, :documentMessage].each do |media_key|
      caption = msg.dig(media_key, :caption)
      return caption if caption.present?
    end

    # 4. Document With Caption
    return msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :caption) if msg.key?(:documentWithCaptionMessage)

    nil
  end

  def attachment_params
    media_key = case message_type
                when :image then :imageMessage
                when :audio then :audioMessage
                when :video then :videoMessage
                when :document then :documentMessage
                when :sticker then :stickerMessage
                end
    return nil unless media_key

    msg = unwrap_ephemeral_message(params.dig(:event, :Message))
    data = msg[media_key]
    return nil unless data.is_a?(Hash)

    {
      external_url: data['URL'],
      file_name: data['fileName'] || "file_#{external_id}",
      mimetype: data['mimetype'],
      thumbnail: data['JPEGThumbnail'],
      media_key: data['mediaKey']
    }
  end

  def sender_phone_number
    jid = extract_jid

    # Reject LIDs as they aren't valid E164 phone numbers
    return nil if jid.blank? || jid.include?('@lid')

    # Format: 556182098580@s.whatsapp.net -> 556182098580
    jid.split('@').first
  end

  def timestamp
    timestamp_val = params.dig(:event, :Info, :Timestamp) || params.dig(:event, :Timestamp)
    return Time.current if timestamp_val.blank?

    begin
      Time.zone.parse(timestamp_val.to_s)
    rescue ArgumentError
      Time.current
    end
  end

  def push_name
    params.dig(:event, :Info, :PushName) || params.dig(:event, :PushName)
  end

  def group_message?
    params.dig(:event, :Info, :IsGroup) || params.dig(:event, :IsGroup)
  end

  private

  def unwrap_ephemeral_message(msg)
    return {} unless msg

    msg.key?(:ephemeralMessage) ? msg.dig(:ephemeralMessage, :message) : msg
  end

  def extract_jid
    if from_me?
      params.dig(:event, :Info, :Chat) || params.dig(:event, :Chat)
    else
      sender = params.dig(:event, :Info, :Sender) || params.dig(:event, :Sender)
      sender_alt = params.dig(:event, :Info, :SenderAlt) || params.dig(:event, :SenderAlt)

      # Prefer @s.whatsapp.net over @lid
      if sender&.include?('@s.whatsapp.net')
        sender
      elsif sender_alt&.include?('@s.whatsapp.net')
        sender_alt
      else
        sender
      end
    end
  end
end
