class Captain::Tools::SearchDocumentationService < Captain::Tools::BaseTool
  LOW_CONFIDENCE_DISTANCE = 0.55

  def self.name
    'search_documentation'
  end
  description 'Search and retrieve documentation from knowledge base'

  param :query, desc: 'Search Query', required: true

  def initialize(assistant, user: nil, conversation: nil)
    @conversation = conversation
    super(assistant, user: user)
  end

  def execute(query:)
    Rails.logger.info { "#{self.class.name}: #{query}" }

    responses = assistant.responses.approved.search(query)

    log_results(query, responses)

    return 'No FAQs found for the given query' if responses.empty? || low_confidence?(responses.first)

    responses.map { |response| format_response(response) }.join
  end

  private

  def log_results(query, responses)
    request_id = extract_request_id
    conversation_id = @conversation&.id
    response_count = responses.length
    scores = responses.map { |response| result_score_payload(response) }
    top_response = responses.first
    top_snippet = top_response&.answer.to_s.strip[0, 200]
    low_confidence = top_response&.neighbor_distance.to_f > LOW_CONFIDENCE_DISTANCE if top_response

    Rails.logger.info(
      "[CAPTAIN][search_documentation] request_id=#{request_id} conversation_id=#{conversation_id} query=#{query.inspect} " \
      "count=#{response_count} results=#{scores} low_confidence=#{low_confidence} top_snippet=#{top_snippet.inspect}"
    )
  end

  def low_confidence?(response)
    return false unless response&.respond_to?(:neighbor_distance)

    response.neighbor_distance.to_f > LOW_CONFIDENCE_DISTANCE
  end

  def result_score_payload(response)
    {
      id: response.id,
      distance: response.neighbor_distance
    }
  end

  def extract_request_id
    return RequestStore.store[:request_id] if defined?(RequestStore) && RequestStore.store[:request_id].present?

    Thread.current[:request_id] || 'unknown'
  end

  def format_response(response)
    formatted_response = "
        Question: #{response.question}
        Answer: #{response.answer}
        "
    if response.documentable.present? && response.documentable.try(:external_link)
      formatted_response += "
          Source: #{response.documentable.external_link}
          "
    end

    formatted_response
  end
end
