module Api
  module V1
    module Accounts
      module Inboxes
        module Jasmine
          class CollectionsController < Api::V1::Accounts::BaseController
            before_action :fetch_inbox

            def index
              # Returns collections linked to this inbox
              collection_ids = @inbox.inbox_collections.pluck(:collection_id)
              @collections = Current.account.jasmine_collections.where(id: collection_ids)
              render json: @collections
            end

            def create
              # Link an existing collection to this inbox
              collection = Current.account.jasmine_collections.find(params[:collection_id])
              link = @inbox.inbox_collections.create!(
                collection: collection,
                priority: params[:priority] || 0
              )
              render json: link
            end

            def destroy
              # Unlink a collection from this inbox
              link = @inbox.inbox_collections.find_by!(collection_id: params[:id])
              link.destroy!
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
end
