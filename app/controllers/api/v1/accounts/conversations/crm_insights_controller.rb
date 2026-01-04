class Api::V1::Accounts::Conversations::CrmInsightsController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation

  def show
    render json: insights_payload
  end

  def refresh
    result = CrmInsights::UpdateService.new(conversation: @conversation, reason: 'manual').call
    render json: insights_payload.merge(meta: build_meta(result))
  end

  private

  def fetch_conversation
    @conversation = Current.account.conversations.find(params[:conversation_id])
  end

  def serialize_insight(insight)
    return nil if insight.blank?

    {
      id: insight.id,
      conversation_id: insight.conversation_id,
      account_id: insight.account_id,
      contact_id: insight.contact_id,
      summary_text: insight.summary_text,
      structured_data: insight.structured_data,
      contact_sessions_count: insight.contact_sessions_count,
      last_contact_at: insight.last_contact_at,
      updated_at: insight.updated_at,
      generated_at: insight.generated_at,
      range_from_message_id: insight.range_from_message_id,
      range_to_message_id: insight.range_to_message_id,
      status: insight.status,
      error_message: insight.error_message,
      schema_version: insight.schema_version,
      model: insight.model,
      confidence: insight.confidence
    }
  end

  def insights_payload
    insights = @conversation.crm_insights.order(generated_at: :desc)
    latest_success = @conversation.latest_crm_insight
    latest_attempt = @conversation.latest_crm_insight_attempt
    {
      crm_insight: serialize_insight(latest_success),
      latest_attempt: serialize_insight(latest_attempt),
      history: insights.limit(20).map { |item| serialize_insight(item) },
      history_count: insights.count
    }
  end

  def build_meta(result)
    return nil if result.blank?

    meta = {
      status: result[:status]
    }

    if result[:status] == 'no_delta'
      last_success = @conversation.latest_crm_insight
      meta[:last_success_at] = last_success&.generated_at
    elsif result[:status] == 'failed'
      meta[:message] = result[:error_message]
    end

    meta
  end
end
