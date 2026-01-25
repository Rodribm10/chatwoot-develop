class Captain::WebhookSenderService
  def initialize(reservation)
    @reservation = reservation
    @unit = reservation.unit
  end

  def perform
    return if @unit&.webhook_url.blank?

    payload = build_payload
    send_webhook(payload)
  end

  private

  def build_payload
    contact = @reservation.contact
    brand = @reservation.brand

    {
      event: 'reservation_update',
      timestamp: Time.current.iso8601,
      reservation: {
        id: @reservation.id,
        suite: @reservation.suite_identifier,
        status: @reservation.status,
        payment_status: @reservation.payment_status,
        check_in: @reservation.check_in_at&.iso8601,
        check_out: @reservation.check_out_at&.iso8601,
        created_at: @reservation.created_at&.iso8601
      },
      financial: {
        total_amount: @reservation.total_amount,
        paid_amount: @reservation.active? ? (@reservation.total_amount * 0.5) : 0.0,
        currency: 'BRL'
      },
      customer: {
        name: contact&.name,
        email: contact&.email,
        phone: contact&.phone_number
      },
      unit: {
        name: @unit.name,
        brand: brand&.name
      },
      metadata: @reservation.metadata
    }
  end

  def send_webhook(payload)
    uri = URI.parse(@unit.webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = payload.to_json

    begin
      response = http.request(request)
      Rails.logger.info "[Captain::WebhookSender] Sent to #{@unit.webhook_url} | Status: #{response.code}"
    rescue StandardError => e
      Rails.logger.error "[Captain::WebhookSender] Failed to send: #{e.message}"
    end
  end
end
