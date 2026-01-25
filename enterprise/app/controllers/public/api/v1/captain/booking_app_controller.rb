class Public::Api::V1::Captain::BookingAppController < ApplicationController
  layout false

  def index
    # This action will serve the React App container
    render :index
  end
end
