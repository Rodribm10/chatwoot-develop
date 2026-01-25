class Public::Api::V1::Captain::WebhooksController < ActionController::API
  def inter_pix
    Rails.logger.info "[Captain::InterWebhook] 🔔 Received Webhook: #{params.to_unsafe_h}"

    # Inter sends an array of "pix" objects
    pix_events = params[:pix] || []

    pix_events.each do |event|
      txid = event[:txid]
      next unless txid

      charge = ::Captain::PixCharge.find_by(txid: txid)

      if charge
        Rails.logger.info "[Captain::InterWebhook] ✅ Found Charge for TXID: #{txid}"

        # Update Charge
        charge.update!(
          status: 'paid',
          paid_at: Time.current,
          raw_webhook_payload: event.to_json
        )

        # Update Reservation
        reservation = charge.reservation
        if reservation
          reservation.update!(
            status: :active,
            payment_status: :paid
          )
          Rails.logger.info "[Captain::InterWebhook] 🏨 Reservation ##{reservation.id} Confirmed!"

          # Trigger N8n Webhook
          ::Captain::WebhookSenderService.new(reservation).perform

          # Send WhatsApp Confirmation
          ::Captain::WhatsappNotificationService.new(reservation).perform
        end
      else
        Rails.logger.warn "[Captain::InterWebhook] ⚠️ Charge NOT found for TXID: #{txid}"
      end
    end

    render json: { status: 'received' }, status: :ok
  end
end
