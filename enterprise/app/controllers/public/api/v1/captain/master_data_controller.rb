class Public::Api::V1::Captain::MasterDataController < ActionController::API
  def show
    # Assuming account_id is passed or derived from domain
    account = Account.find(params[:account_id])

    brands = account.captain_brands.includes(:units, :pricings)
    extras = account.captain_extras.where(active: true).order(:order)
    suites = account.captain_suites.all

    begin
      config = account.captain_configuration || account.create_captain_configuration!
    rescue StandardError => e
      Rails.logger.error "Failed to create Captain Configuration: #{e.message}"
      config = { title: 'Reserva Rápida', subtitle: 'Agende sua visita', primary_color: '#1E90FF', secondary_color: '#1B3B5F' }
    end

    render json: {
      app_config: config,
      brands: brands.as_json(include: :units),
      pricings: account.captain_pricings.as_json,
      extras: extras.as_json,
      suites: suites.as_json
    }
  end
end
