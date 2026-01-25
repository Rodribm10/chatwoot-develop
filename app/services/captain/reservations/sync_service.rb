module Captain
  module Reservations
    class SyncService
      PLUG_PLAY_API_BASE = 'https://oxpi.com.br/api/PlugPlay/api/Reserva'

      def initialize(unit)
        @unit = unit
        @account = unit.account
        @inbox = unit.inbox # Assuming unit is linked to an inbox, or we fallback
      end

      def perform
        return unless @unit.reservations_sync_enabled?
        return unless @unit.plug_play_id.present? && @unit.plug_play_token.present?

        page = 1
        loop do
          reservations_data = fetch_page(page)
          break if reservations_data.empty?

          reservations_data.each do |reservation_data|
            process_reservation(reservation_data)
          end

          page += 1
          # Safety break to avoid infinite loops in case of API issues
          break if page > 50
        end

        @unit.update(last_synced_at: Time.current)
      end

      private

      def fetch_page(page)
        url = "#{PLUG_PLAY_API_BASE}?exibicao=0&pagina=#{page}"
        response = HTTParty.get(url, headers: headers)

        if response.success?
          begin
            JSON.parse(response.body)
          rescue StandardError
            []
          end
        else
          Rails.logger.error "PlugPlay Sync Error: #{response.code} - #{response.body}"
          []
        end
      end

      def headers
        {
          'PLUG-PLAY-ID' => @unit.plug_play_id,
          'PLUG-PLAY-TOKEN' => @unit.plug_play_token,
          'Content-Type' => 'application/json'
        }
      end

      def process_reservation(data)
        external_id = data['id']
        return if external_id.blank?

        reservation = @unit.captain_reservations.find_or_initialize_by(integracao_id: external_id)

        # Resolve Contact
        contact = find_or_create_contact(data)

        # Map Attributes
        reservation.account = @account
        reservation.inbox = @inbox || @account.inboxes.first # Fallback if unit has no inbox
        reservation.contact = contact
        reservation.contact_inbox = contact.contact_inboxes.find_by(inbox: reservation.inbox)

        # If contact_inbox missing (new contact created without association to this inbox), create it
        if reservation.contact_inbox.nil?
          reservation.contact_inbox = ContactInbox.create!(contact: contact, inbox: reservation.inbox, source_id: contact.id)
        end

        reservation.suite_identifier = data['suiteRef']
        reservation.check_in_at = parse_date(data['dataInicio']) # Format: 2026-01-22T00:00:00
        reservation.check_out_at = parse_date(data['saidaPrevistaOuNegociada'])

        if reservation.suite_identifier.blank? || reservation.check_in_at.blank? || reservation.check_out_at.blank?
          Rails.logger.warn "PlugPlay Sync Skip: missing suite/dates for reservation #{external_id}"
          return
        end

        reservation.total_amount = data['totalAPagar']

        # Status Mapping
        reservation.status = map_status(data)

        reservation.metadata ||= {}
        reservation.metadata['raw_plug_play_data'] = data
        reservation.metadata['guest_name'] = data['nome']
        reservation.metadata['guest_email'] = data['email']
        reservation.metadata['guest_phone'] = data['telefone']
        reservation.metadata['notes'] = data['observacoes']
        reservation.metadata['source_tag'] = @unit.reservation_source_tag if @unit.reservation_source_tag.present?

        reservation.save!
      rescue StandardError => e
        if e.is_a?(ActiveRecord::RecordInvalid) && e.record
          Rails.logger.error "Error syncing reservation #{data['id']}: #{e.record.errors.full_messages.join(', ')}"
          Rails.logger.error "Reservation attrs: unit_id=#{@unit.id} inbox_id=#{reservation&.inbox_id} contact_id=#{reservation&.contact_id} contact_inbox_id=#{reservation&.contact_inbox_id} suite=#{reservation&.suite_identifier} check_in=#{reservation&.check_in_at} check_out=#{reservation&.check_out_at} status=#{reservation&.status}"
        else
          Rails.logger.error "Error syncing reservation #{data['id']}: #{e.message}"
        end
      end

      def find_or_create_contact(data)
        phone = normalize_phone_number(data['telefone'])
        email = data['email']
        name = data['nome']

        contact = nil

        # Try finding by phone
        contact = @account.contacts.find_by(phone_number: phone) if phone.present?

        # Try finding by email
        contact = @account.contacts.find_by(email: email) if contact.nil? && email.present?

        # Create if not found
        if contact.nil?
          contact = @account.contacts.create!(
            name: name,
            email: email,
            phone_number: phone
          )
        end

        contact
      end

      def normalize_phone_number(raw_phone)
        digits = raw_phone.to_s.gsub(/[^\d]/, '')
        return nil if digits.blank?

        digits = "55#{digits}" if digits.length == 10 || digits.length == 11

        return nil if digits.length < 10 || digits.length > 15

        "+#{digits}"
      end

      def parse_date(date_string)
        return nil if date_string.blank?

        Time.zone.parse(date_string)
      rescue StandardError
        nil
      end

      def map_status(data)
        # MVP Logic based on dates and 'cancelada'
        return :cancelled if data['cancelada'] == true

        check_in = parse_date(data['dataInicio'])
        check_out = parse_date(data['saidaPrevistaOuNegociada'])
        now = Time.current

        return :scheduled unless check_in && check_out

        if now >= check_out
          :completed
        elsif now >= check_in && now < check_out
          :active
        else
          :scheduled
        end
      end
    end
  end
end
