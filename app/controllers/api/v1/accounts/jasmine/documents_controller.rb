module Api
  module V1
    module Accounts
      module Jasmine
        class DocumentsController < Api::V1::Accounts::BaseController
          before_action :fetch_collection
          
          def index
            render json: @collection.documents.order(created_at: :desc)
          end

          def create
            @document = @collection.documents.new(document_params)
            @document.account = Current.account
            
            if @document.save
              render json: @document
            else
              render json: { error: @document.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          def destroy
            @document = @collection.documents.find(params[:id])
            @document.destroy!
            head :no_content
          end

          private

          def fetch_collection
            @collection = Current.account.jasmine_collections.find(params[:collection_id])
          end

          def document_params
            params.require(:document).permit(:title, :content)
          end
        end
      end
    end
  end
end
