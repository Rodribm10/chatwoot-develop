module Captain
  class WhatsappNotificationService
    def initialize(reservation)
      @reservation = reservation
      @unit = reservation.unit
      @account = reservation.account
      @contact = reservation.contact
      @conversation = reservation.conversation
    end

    def perform
      return unless valid_for_sending?

      # Find sender (Captain Bot or First Admin)
      sender = find_sender

      # Build Message Content
      content = build_message_content

      # Send Message
      ::Messages::MessageBuilder.new(
        sender,
        @conversation,
        {
          content: content,
          private: false,
          message_type: 'outgoing'
        }
      ).perform

      Rails.logger.info "[Captain::WhatsappNotification] 📨 Message sent to #{@contact.name} (Reserva ##{@reservation.id})"
    rescue StandardError => e
      Rails.logger.error "[Captain::WhatsappNotification] ❌ Error sending message: #{e.message}"
    end

    private

    def valid_for_sending?
      unless @unit&.inbox_id
        Rails.logger.warn "[Captain::WhatsappNotification] ⚠️ No Inbox configured for Unit ##{@unit&.id}"
        return false
      end

      # Ensure conversation belongs to the correct inbox?
      # If the reservation conversation is in a different inbox (e.g. Web Widget), we might need to create a new conversation in the WhatsApp Inbox.
      # For now, let's assume the reservation conversation IS the one we want to reply to, OR we simply send to that conversation.
      # BUT, if the user requested "Send using the Unit's specific inbox", we must respect that.

      if @conversation.inbox_id != @unit.inbox_id
        # We need to find or create a conversation in the Target Inbox
        target_inbox = @account.inboxes.find_by(id: @unit.inbox_id)
        unless target_inbox
          Rails.logger.error "[Captain::WhatsappNotification] ❌ Target Inbox ##{@unit.inbox_id} not found"
          return false
        end

        # Find contact inbox for the target inbox
        contact_inbox = ::ContactInbox.find_by(contact_id: @contact.id, inbox_id: target_inbox.id)

        # If contact doesn't exist in that inbox, we might need to create source_id (phone)?
        # Actually, if it's a phone-based inbox (WhatsApp), the contact needs to have the phone number.
        contact_inbox ||= ::ContactInbox.create!(
          contact_id: @contact.id,
          inbox_id: target_inbox.id,
          source_id: @contact.phone_number # Assuming source_id for WA is phone
        )

        # Find or Create Conversation in Target Inbox
        @conversation = ::Conversation.create!(
          account_id: @account.id,
          inbox_id: target_inbox.id,
          contact_id: @contact.id,
          contact_inbox_id: contact_inbox.id,
          status: :open
        )
      end

      true
    end

    def find_sender
      # Try to find a Captain Agent Bot first
      # Valid logic: defaults to the account administrator
      @account.administrators.first || @account.users.first
    end

    def build_message_content
      # Format Dates
      check_in = @reservation.check_in_at.strftime('%d/%m/%Y %H:%M')

      "Olá #{@contact.name}, confirmamos o pagamento da sua reserva no #{@unit.name}! 🎉\n\n" \
        "🏨 *Reserva:* ##{@reservation.id}\n" \
        "📅 *Check-in:* #{check_in}\n" \
        "✅ *Status:* Confirmado\n\n" \
        'Estamos ansiosos para recebê-lo!'
    end
  end
end
