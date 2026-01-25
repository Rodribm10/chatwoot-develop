class Whatsapp::IncomingMessageWuzapiService < IncomingMessageBaseService
  def perform
    parser = Whatsapp::Providers::Wuzapi::PayloadParser.new(params)
    Rails.logger.info "WuzapiService: Processing #{parser.message_type} from #{parser.sender_phone_number}"

    # 1. Message Type Check
    if parser.message_type == :ignore
      Rails.logger.info 'WuzAPI: Ignored event type (ReadReceipt/Other)'
      return
    end

    allowed_types = [:text, :image, :audio, :video, :document, :sticker, :chat_presence]
    unless allowed_types.include?(parser.message_type)
      Rails.logger.info "WuzAPI: Unsupported message type: #{parser.message_type}"
      return
    end

    # 2. V1 Scope: Ignore Groups
    if parser.group_message?
      Rails.logger.info "WuzAPI: Ignoring group message (ID: #{parser.external_id})"
      return
    end

    # 3. Strong Dedupe (Using WAID prefix)
    clean_source_id = "WAID:#{parser.external_id}"
    if parser.message_type != :chat_presence && parser.external_id.present? && Message.exists?(source_id: clean_source_id, inbox_id: inbox.id)
      Rails.logger.info "WuzAPI: Ignoring duplicate message (ID: #{clean_source_id})"
      return
    end

    if parser.sender_phone_number.blank?
      Rails.logger.warn "WuzAPI: Skipping processing for event with no valid phone (Type: #{parser.message_type})"
      return
    end

    # 4. Process
    Rails.logger.info "WuzAPI: Processing message from #{parser.sender_phone_number} (Type: #{parser.message_type})"

    ActiveRecord::Base.transaction do
      @contact = find_or_create_contact(parser)
      @conversation = find_or_create_conversation(@contact)

      if parser.message_type == :chat_presence
        status = parser.presence_state == 'composing' ? 'on' : 'off'
        @conversation.toggle_typing_status(status)
        return
      end

      # Create Message First (Clean source_id) - Build, not save yet
      @message = build_message(parser, @conversation, clean_source_id)

      # Attach media BEFORE saving (Chatwoot pattern)
      attach_files(parser) if [:image, :audio, :video, :document, :sticker].include?(parser.message_type)

      # Now save with attachments
      @message.save!
      Rails.logger.info "WuzAPI: Message created: #{@message.id} (SourceID: #{clean_source_id})"
    end
  rescue StandardError => e
    Rails.logger.error "WuzAPI Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def find_or_create_contact(parser)
    phone = parser.sender_phone_number
    normalized_phone = "+#{phone}"

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone,
      inbox: inbox,
      contact_attributes: {
        name: parser.push_name || phone,
        phone_number: normalized_phone
      }
    ).perform

    contact_inbox.contact
  end

  def find_or_create_conversation(contact)
    conversation = inbox.conversations.where(contact_id: contact.id)
                        .where.not(status: :resolved)
                        .last

    conversation || ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: ContactInbox.find_by(contact_id: contact.id, inbox_id: inbox.id)&.id
    )
  end

  def build_message(parser, conversation, clean_source_id)
    is_outgoing = parser.from_me?

    msg_params = {
      content: parser.text_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: is_outgoing ? :outgoing : :incoming,
      sender: is_outgoing ? nil : @contact,
      source_id: clean_source_id,
      created_at: parser.timestamp
    }

    # Handle Replies
    # Handle Reply Logic (Aligned with Reference)
    if (reply_id = parser.in_reply_to_external_id).present?
      clean_reply_id = "WAID:#{reply_id}"

      # Strict lookup within conversation to prevent cross-inbox leaks
      original_message = conversation.messages.find_by(source_id: clean_reply_id)

      if original_message
        msg_params[:in_reply_to_id] = original_message.id
      else
        # Fallback: Store ID for UI "Replying to..." display even if not linked
        msg_params[:content_attributes] = { in_reply_to_external_id: clean_reply_id }
      end
    end

    # Use .build so we can attach files before .save!
    conversation.messages.build(msg_params)
  end

  def attach_files(parser)
    attachment_data = parser.attachment_params
    return if attachment_data.blank? || attachment_data[:external_url].blank?

    begin
      Rails.logger.info "WuzAPI: Processing attachment (URL: #{attachment_data[:external_url]}, File: #{attachment_data[:file_name]})"

      # 1. Download/Decrypt to get a file
      file_io = download_or_decrypt_media(attachment_data, parser.message_type)
      return if file_io.blank?

      # 2. Determine filename
      original_filename = attachment_data[:file_name] || "wuzapi_#{Time.now.to_i}"
      extension = File.extname(original_filename)
      extension = detect_extension(attachment_data[:mimetype], parser.message_type) if extension.blank?
      final_filename = "#{File.basename(original_filename, '.*')}#{extension}"

      # 3. Attach using Chatwoot's standard pattern
      @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_content_type(parser.message_type),
        file: {
          io: file_io,
          filename: final_filename,
          content_type: attachment_data[:mimetype] || 'application/octet-stream'
        }
      )

      Rails.logger.info "WuzAPI: Attachment queued for save (#{final_filename})"

    rescue StandardError => e
      Rails.logger.error "WuzAPI Attachment Error: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
    end
  end

  def download_or_decrypt_media(attachment_data, message_type)
    media_url = attachment_data[:external_url]

    # METHOD 1: Use WuzAPI's /chat/downloadimage endpoint (returns DECRYPTED media)
    # This is the equivalent of Cloud API's media download
    begin
      Rails.logger.info 'WuzAPI: Attempting download via WuzAPI endpoint...'
      wuzapi_response = wuzapi_client.download_media(wuzapi_token, media_url)

      if wuzapi_response.is_a?(Hash) && wuzapi_response['data'].present?
        # WuzAPI returns base64 in 'data' field
        image_data = wuzapi_response['data']
        # Strip data URI prefix if present
        image_data = image_data.sub(/^data:.*?;base64,/, '') if image_data.start_with?('data:')

        decoded = Base64.decode64(image_data)
        if decoded.bytesize > 1000 # Valid image should be > 1KB
          Rails.logger.info 'WuzAPI: Download via endpoint SUCCESS'
          return StringIO.new(decoded)
        end
      end
    rescue StandardError => e
      Rails.logger.warn "WuzAPI: Endpoint download failed - #{e.message}"
    end

    # METHOD 2: Try local decryption if we have mediaKey
    if attachment_data[:media_key].present?
      Rails.logger.info 'WuzAPI: Attempting local decryption (mediaKey present)...'
      decrypted = Whatsapp::DecryptionService.new(
        media_url,
        attachment_data[:media_key],
        file_content_type(message_type)
      ).decrypt

      return decrypted if decrypted

      Rails.logger.warn 'WuzAPI: Local decryption failed...'
    end

    # METHOD 3: Direct download (only works for non-encrypted or already-decrypted URLs)
    Rails.logger.info "WuzAPI: Direct download from #{media_url}"
    Down.download(
      media_url,
      open_timeout: 10,
      read_timeout: 30,
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
    )
  rescue StandardError => e
    Rails.logger.error "WuzAPI: All download methods failed - #{e.message}"
    nil
  end

  def wuzapi_client
    @wuzapi_client ||= Wuzapi::Client.new(@inbox.channel.provider_config['wuzapi_base_url'])
  end

  def wuzapi_token
    @inbox.channel.wuzapi_user_token
  end

  def detect_extension(mimetype, message_type)
    return '.jpg' if message_type == :image || message_type == :sticker
    return '.mp3' if message_type == :audio
    return '.mp4' if message_type == :video

    case mimetype
    when 'image/png' then '.png'
    when 'image/webp' then '.webp'
    when 'image/gif' then '.gif'
    when 'audio/ogg' then '.ogg'
    when 'video/webm' then '.webm'
    else '.bin'
    end
  end

  def file_content_type(message_type)
    case message_type
    when :image, :sticker then :image
    when :audio then :audio
    when :video then :video
    else :file
    end
  end
end
