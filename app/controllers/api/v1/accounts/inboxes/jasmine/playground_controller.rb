class Api::V1::Accounts::Inboxes::Jasmine::PlaygroundController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :fetch_config

  def test
    return render json: { error: 'Message is required' }, status: :bad_request if params[:message].blank?
    return render json: { error: 'Jasmine is not enabled for this inbox' }, status: :unprocessable_entity unless @config&.is_enabled?

    begin
      response = generate_response(params[:message])
      render json: build_success_payload(response)
    rescue StandardError => e
      handle_error(e)
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def fetch_config
    @config = ::Jasmine::InboxConfig.find_by(
      account: Current.account,
      inbox: @inbox
    )
  end

  def generate_response(content)
    # Create a mock message object for BrainService
    mock_message = OpenStruct.new(content: content, inbox: @inbox, conversation: mock_conversation)
    ::Jasmine::BrainService.new(inbox: @inbox, conversation: mock_conversation, message: mock_message).respond
  end

  def build_success_payload(response)
    {
      response: response,
      debug: {
        model: @config.model,
        temperature: @config.temperature,
        rag_threshold: @config.rag_distance_threshold
      }
    }
  end

  def handle_error(err)
    Rails.logger.error "[Jasmine::Playground] Error: #{err.message}\n#{err.backtrace.first(5).join("\n")}"
    render json: { error: err.message }, status: :internal_server_error
  end

  def mock_conversation
    # Create a minimal mock conversation for playground testing
    @mock_conversation ||= begin
      mock = OpenStruct.new(
        id: 0,
        account_id: Current.account.id,
        inbox_id: @inbox.id,
        custom_attributes: { 'jasmine_state' => {} }
      )

      # Mock messages method to return empty array that responds to query methods
      def mock.messages
        []
      end

      # Mock update! to do nothing (playground doesn't need state persistence)
      def mock.update!(**attrs)
        # no-op for playground
      end

      mock
    end
  end
end
