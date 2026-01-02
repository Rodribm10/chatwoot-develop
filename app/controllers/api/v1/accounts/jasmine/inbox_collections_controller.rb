module Api
  module V1
    module Accounts
      module Jasmine
        class InboxCollectionsController < Api::V1::Accounts::BaseController
          before_action :fetch_inbox

          def index
            render json: @inbox.inbox_collections.includes(:collection)
          end

          def create
            collection = Current.account.jasmine_collections.find(params[:collection_id])
            
            link = @inbox.inbox_collections.new(
              collection: collection,
              account: Current.account,
              priority: params[:priority] || 0
            )

            if link.save
              render json: link
            else
              render json: { error: link.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          def destroy
            link = @inbox.inbox_collections.find_by!(collection_id: params[:collection_id])
            link.destroy
            head :no_content
          end

          private

          def fetch_inbox
            @inbox = Current.account.inboxes.find(params[:inbox_id])
          end
        end
      end
    end
  end
end
