class Webhooks::WuzapiController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :fetch_inbox
  before_action :verify_secret

  def process_payload
    # Normalize payload keys if necessary based on Wuzapi behavior
    # Assuming Wuzapi sends standard WA format or we adapt it here
    # For now, just logging to verify reception
    Rails.logger.info "Wuzapi Webhook Received for Inbox #{@inbox.id}: #{params.inspect}"

    # TODO: Implement actual message processing logic:
    # 1. Parse payload to extract Phone, Body, Type (Text/Image)
    # 2. Find or create Contact
    # 3. Create Message in Conversation
    
    # Example adapter call (to be implemented):
    # Whatsapp::Providers::WuzapiAdapter.new(@inbox).process(params)

    head :ok
  end

  private

  def fetch_inbox
    @inbox = Inbox.find(params[:inbox_id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def verify_secret
    secret = params[:secret]
    stored_secret = @inbox.channel.provider_config['webhook_secret']

    if secret.blank? || secret != stored_secret
      Rails.logger.warn "Wuzapi Webhook: Invalid secret for Inbox #{@inbox.id}. Received: #{secret}"
      head :unauthorized
    end
  end
end
