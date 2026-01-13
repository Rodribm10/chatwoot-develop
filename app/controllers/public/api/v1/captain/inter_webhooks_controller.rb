class Public::Api::V1::Captain::InterWebhooksController < ActionController::API
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create
    payload = JSON.parse(request.body.read)
    pix_data = payload['pix']

    if pix_data.blank?
      render json: { message: 'Ignored: No pix data' }, status: :ok
      return
    end

    txid = pix_data['txid']
    e2eid = pix_data['endToEndId']

    # Idempotency Check
    existing_charge = ::Captain::PixCharge.find_by(e2eid: e2eid)
    if existing_charge
      render json: { message: 'Already processed' }, status: :ok
      return
    end

    # Find Charge
    charge = ::Captain::PixCharge.find_by(txid: txid)
    unless charge
      render json: { message: 'Charge not found' }, status: :ok # Return 200 to satisfy Inter retry policy
      return
    end

    # Update Charge
    charge.update!(
      status: 'paid',
      e2eid: e2eid,
      paid_at: Time.current,
      raw_webhook_payload: payload
    )

    # Update Reservation
    charge.reservation.update!(payment_status: 'paid')

    # Notify Chat
    notify_chat(charge.reservation)

    render json: { message: 'Received' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Webhook Error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def notify_chat(reservation)
    return unless reservation.conversation_id

    conversation = Conversation.find(reservation.conversation_id)

    Messages::CreateService.new(
      conversation: conversation,
      params: {
        content: "✅ Pagamento confirmado! Sua reserva ##{reservation.id} na unidade #{reservation.captain_unit.name} está garantida.",
        message_type: :outgoing
      }
    ).perform
  rescue StandardError => e
    Rails.logger.error "Failed to notify chat: #{e.message}"
  end
end
