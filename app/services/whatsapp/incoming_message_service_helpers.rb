module Whatsapp::IncomingMessageServiceHelpers
  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def processed_params
    @processed_params ||= params
  end

  def account
    @account ||= inbox.account
  end

  def message_type
    @processed_params[:messages].first[:type]
  end

  def create_message(message)
    # Find original message if it's a reply
    in_reply_to_id = nil
    if @in_reply_to_external_id.present?
      Rails.logger.info "WuzAPI Reply Lookup: Checking stanzaID=#{@in_reply_to_external_id}"

      original_message = Message.find_by(source_id: @in_reply_to_external_id)
      # Fallback to search by standard ID if source_id format differs
      original_message ||= Message.find_by(source_id: "WAID:#{@in_reply_to_external_id}")

      if original_message
        Rails.logger.info "WuzAPI Reply Lookup: MATCH FOUND! ID=#{original_message.id}"
        in_reply_to_id = original_message.id
      else
        Rails.logger.warn "WuzAPI Reply Lookup: NO MATCH FOUND for stanzaID=#{@in_reply_to_external_id}"
        Rails.logger.warn "WuzAPI Debug: Last 5 source_ids in DB: #{Message.where(inbox_id: @inbox.id).last(5).pluck(:source_id)}"
      end
    end

    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message[:id].to_s,
      in_reply_to_id: in_reply_to_id,
      in_reply_to_external_id: @in_reply_to_external_id
    )
  end

  def attach_contact(contact)
    phones = contact[:phones]
    phones = [{ phone: 'Phone number is not available' }] if phones.blank?

    name_info = contact['name'] || {}
    contact_meta = {
      firstName: name_info['first_name'],
      lastName: name_info['last_name']
    }.compact

    phones.each do |phone|
      @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_content_type(message_type),
        fallback_title: phone[:phone].to_s,
        meta: contact_meta
      )
    end
  end

  def update_contact_with_profile_name(contact_params)
    profile_name = contact_params.dig(:profile, :name)
    return if profile_name.blank?
    return if @contact.name == profile_name

    # Only update if current name exactly matches the phone number or formatted phone number
    return unless contact_name_matches_phone_number?

    @contact.update!(name: profile_name)
  end

  def contact_name_matches_phone_number?
    phone_number = "+#{@processed_params[:messages].first[:from]}"
    formatted_phone_number = TelephoneNumber.parse(phone_number).international_number
    @contact.name == phone_number || @contact.name == formatted_phone_number
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title) ||
      message.dig(:name, :formatted_name)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
  end

  def unprocessable_message_type?(message_type)
    %w[reaction ephemeral unsupported request_welcome].include?(message_type)
  end

  def processed_waid(waid)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(waid, :cloud)
  end

  def error_webhook_event?(message)
    message.key?('errors')
  end

  def log_error(message)
    Rails.logger.warn "Whatsapp Error: #{message['errors'][0]['title']} - contact: #{message['from']}"
  end

  def process_in_reply_to(message)
    # 1. Extended Text Message
    if message.dig('extendedTextMessage', 'contextInfo').present?
      ctx = message['extendedTextMessage']['contextInfo']
      @in_reply_to_external_id = ctx['stanzaID'] || ctx['stanzaId']
      return
    end

    # 2. Media Messages (Image, Video, Audio, Document, Sticker)
    [:imageMessage, :videoMessage, :audioMessage, :documentMessage, :stickerMessage].each do |media_key|
      next if message.dig(media_key.to_s, 'contextInfo').blank?

      ctx = message[media_key.to_s]['contextInfo']
      @in_reply_to_external_id = ctx['stanzaID'] || ctx['stanzaId']
      return
    end

    # 3. Fallback for other providers
    @in_reply_to_external_id = message['context']&.[]('id')
  end

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = Message.find_by(source_id: source_id)
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:messages].first[:id])
    Redis::Alfred.get(key)
  end

  def cache_message_source_id_in_redis
    return if @processed_params.try(:[], :messages).blank?

    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:messages].first[:id])
    ::Redis::Alfred.setex(key, true)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:messages].first[:id])
    ::Redis::Alfred.delete(key)
  end
end
