module Api
  module V1
    module Accounts
      module Jasmine
        class CollectionsController < Api::V1::Accounts::BaseController
          before_action :find_collection, only: [:destroy]

          def index
            scope = Current.account.jasmine_collections
            scope = scope.where(visibility: params[:visibility]) if params[:visibility]
            render json: scope
          end

          def create
            @collection = Current.account.jasmine_collections.new(collection_params)

            if @collection.save
              # Auto-link to inbox if owner_inbox_id provided
              if @collection.owner_inbox_id
                inbox = Current.account.inboxes.find_by(id: @collection.owner_inbox_id)
                inbox&.inbox_collections&.create(collection: @collection, priority: 10)
              end
              render json: @collection
            else
              render json: { error: @collection.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          def destroy
            if @collection.destroy
              head :no_content
            else
              render json: { error: @collection.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          private

          def find_collection
            @collection = Current.account.jasmine_collections.find(params[:id])
          end

          def collection_params
            params.require(:collection).permit(:name, :description, :visibility, :owner_inbox_id)
          end
        end
      end
    end
  end
end

