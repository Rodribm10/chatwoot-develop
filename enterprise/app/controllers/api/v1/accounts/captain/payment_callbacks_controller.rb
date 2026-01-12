class Api::V1::Accounts::Captain::PaymentCallbacksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, only: [:update]
  # We might want a shared secret header here for security from N8N

  def update
    reservation = ::Captain::Reservation.find_by!(integracao_id: params[:id])

    if params[:status] == 'paid'
      reservation.active!
      reservation.payment_paid!

      # Optional: Send confirmation WA to user via Chatwoot internal methods
      # Conversation creation logic etc.

      render json: { status: 'ok' }
    else
      render json: { status: 'ignored' }
    end
  end
end
