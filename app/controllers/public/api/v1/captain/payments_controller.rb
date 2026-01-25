class Public::Api::V1::Captain::PaymentsController < ApplicationController
  layout false
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :check_current_user_is_active, raise: false

  def show
    @charge = GlobalID::Locator.locate_signed(params[:token], purpose: :pix_payment)

    return unless @charge.nil?

    render plain: 'Link de pagamento inválido ou expirado.', status: :not_found
    return

    # @charge is available for the view
    # It should be a Captain::PixCharge model
  end
end
