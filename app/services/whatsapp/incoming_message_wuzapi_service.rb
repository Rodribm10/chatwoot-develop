module Whatsapp
  class IncomingMessageWuzapiService < IncomingMessageBaseService
    def perform
      parser = Whatsapp::Providers::Wuzapi::PayloadParser.new(params)

      # 1. Message Type Check (V1: Text + Presence)
      # Fail fast for unsupported types (like ReadReceipts)
      return unless [:text, :chat_presence].include?(parser.message_type)

      # 2. V1 Scope: Ignore Groups
      if parser.group_message?
        Rails.logger.info "WuzAPI: Ignoring group message (ID: #{parser.external_id})"
        return
      end

      # 3. Strong Dedupe (Critical for Sync)
      # Skip dedupe for ChatPresence as it doesn't have a unique ID
      if parser.message_type != :chat_presence && parser.external_id.present? && Message.exists?(source_id: parser.external_id, inbox_id: inbox.id)
        Rails.logger.info "WuzAPI: Ignoring duplicate message (ID: #{parser.external_id})"
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
        Rails.logger.info "WuzAPI: Contact found/created: #{@contact.id}"

        @conversation = find_or_create_conversation(@contact)
        Rails.logger.info "WuzAPI: Conversation found/created: #{@conversation.id}"

        if parser.message_type == :chat_presence
          status = parser.presence_state == 'composing' ? 'on' : 'off'
          @conversation.toggle_typing_status(status)
          return
        end

        message = create_message(parser, @conversation)
        Rails.logger.info "WuzAPI: Message created: #{message.id}"
      end
    rescue StandardError => e
      Rails.logger.error "WuzAPI Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    private

    def find_or_create_contact(parser)
      # Normalize phone
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

    def create_message(parser, conversation)
      is_outgoing = parser.from_me?

      conversation.messages.create!(
        content: parser.text_content,
        account_id: inbox.account_id,
        inbox_id: inbox.id,
        message_type: is_outgoing ? :outgoing : :incoming,
        sender: is_outgoing ? nil : @contact,
        source_id: parser.external_id,
        created_at: parser.timestamp
      )
    end
  end
end
