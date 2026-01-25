class Api::V1::Accounts::Captain::UnitsController < Api::V1::Accounts::BaseController
  def index
    @units = Current.account.captain_units
  end

  def show
    @unit = Current.account.captain_units.find(params[:id])
  end

  def create
    @unit = Current.account.captain_units.new(unit_params)
    @unit.captain_brand = Current.account.captain_brands.first # Default brand logic for now

    if @unit.save
      render 'show', status: :created
    else
      render_error_response(@unit)
    end
  end

  def update
    @unit = Current.account.captain_units.find(params[:id])

    if @unit.update(unit_params)
      render 'show'
    else
      render_error_response(@unit)
    end
  end

  def destroy
    @unit = Current.account.captain_units.find(params[:id])
    @unit.destroy
    head :ok
  end

  private

  def unit_params
    params.require(:unit).permit(
      :name,
      :status,
      :reservations_sync_enabled,
      :plug_play_id,
      :plug_play_token,
      :webhook_url,
      :leader_whatsapp,
      :reservation_source_tag,
      :inter_client_id,
      :inter_client_secret,
      :inter_pix_key,
      :inter_account_number,
      visible_suite_categories: [],
      suite_category_images: {}
    )
  end
end
