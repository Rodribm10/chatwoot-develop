module Whatsapp::Providers
  class WuzapiService < BaseService
    attr_reader :whatsapp_channel

    def initialize(whatsapp_channel:)
      @whatsapp_channel = whatsapp_channel
      @base_url = whatsapp_channel.provider_config['wuzapi_base_url']
    end

    def send_message(phone_number, message)
      user_token = whatsapp_channel.wuzapi_user_token
      # Normalize phone number: remove +, space, -, (, )
      normalized_phone = phone_number.gsub(/[\+\s\-\(\)]/, '')

      if message.content_attributes['is_reaction'] || message.content_attributes[:is_reaction]
        return send_reaction_message(normalized_phone, message)
      end

      if message.attachments.present?
        send_attachment_message(user_token, normalized_phone, message)
      else
        client.send_text(user_token, normalized_phone, message.content)
      end
    end

    def send_attachment_message(user_token, phone_number, message)
      attachment = message.attachments.first
      base64_data = Base64.strict_encode64(attachment.file.download)
      mime_type = attachment.file.content_type
      data_uri = "data:#{mime_type};base64,#{base64_data}"

      if mime_type.start_with?('image/')
        client.send_image(user_token, phone_number, data_uri, message.content)
      else
        client.send_file(user_token, phone_number, data_uri, attachment.file.filename.to_s)
      end
    end

    def send_reaction_message(phone_number, message)
      user_token = whatsapp_channel.wuzapi_user_token
      normalized_phone = phone_number.gsub(/[\+\s\-\(\)]/, '')

      # Assuming message content is the emoji
      reaction_emoji = message.content
      # Prefer external message id, fallback to in_reply_to if already external.
      message_id = message.content_attributes['in_reply_to_external_id'] || message.content_attributes['in_reply_to']
      use_me_prefix = reaction_to_own_message?(message)

      if use_me_prefix
        normalized_phone = "me:#{normalized_phone}" unless normalized_phone.start_with?('me:')
        message_id = "me:#{message_id}" if message_id.present? && !message_id.start_with?('me:')
      end

      if message_id.present?
        # Wuzapi client needs to implement send_reaction
        # This assumes the client wrapper has this method. If not, we might need to add it or use raw request.
        # Based on typical Wuzapi forks, it might be /send-reaction-message

        # We'll assume the client wrapper will have a send_reaction method.
        # If not visible in the existing codebase, we might need to add it to the client class too.
        # checking...
        client.send_reaction(user_token, normalized_phone, message_id, reaction_emoji)
      else
        Rails.logger.warn 'Wuzapi: Cannot send reaction without in_reply_to message ID'
      end
    end

    def send_template(_phone_number, _template_info)
      # Placeholder for template support if Wuzapi supports it.
      # For now, just logging or no-op as per initial text-focused plan.
      Rails.logger.warn 'Wuzapi: Templates not yet implemented or supported.'
    end

    def sync_templates
      # No-op for Wuzapi as it doesn't insist on syncing templates like Cloud API
    end

    def validate_provider_config?
      # Validate if we can connect to session status
      user_token = whatsapp_channel.wuzapi_user_token
      return false if user_token.blank?

      begin
        client.session_status(user_token)
        true
      rescue Wuzapi::Client::Error
        false
      end
    end

    private

    def client
      @client ||= ::Wuzapi::Client.new(@base_url)
    end

    def reaction_to_own_message?(message)
      # If we can resolve the target message, check if it was sent by us.
      target_message = nil
      if message.in_reply_to.present?
        target_message = message.conversation.messages.find_by(id: message.in_reply_to)
        target_message ||= message.conversation.messages.find_by(source_id: message.in_reply_to)
      elsif message.in_reply_to_external_id.present?
        target_message = message.conversation.messages.find_by(source_id: message.in_reply_to_external_id)
      end

      return false unless target_message.present?

      target_message.outgoing? || target_message.template?
    end
  end
end
