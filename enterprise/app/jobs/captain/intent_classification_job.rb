class Captain::IntentClassificationJob < ApplicationJob
  queue_as :default

  CATEGORIES = %w[
    valores
    disponibilidade
    localizacao
    checkin_checkout
    pet_friendly
    cancelamento
    cafe_da_manha
    estacionamento
    pagamento
    outros
  ].freeze

  def perform(conversation_id, message_content)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    # Prevent labeling if already labeled recently (optional optimization, skipping for MVP to ensure accuracy)
    # For MVP, we classify every user message to capture the flow, or we could limit to the first few.
    # Let's classify every message that is substantial enough.
    return if message_content.to_s.strip.length < 5

    intent = classify_intent(message_content)
    return unless intent.present? && CATEGORIES.include?(intent)

    label_name = "duvida:#{intent}"

    # Add label if not present
    unless conversation.labels.exists?(name: label_name)
      conversation.labels << Label.find_or_create_by(title: label_name, account_id: conversation.account_id)
      Rails.logger.info "[IntentClassification] Applied label '#{label_name}' to conversation #{conversation.id}"
    end
  rescue StandardError => e
    Rails.logger.error "[IntentClassification] Failed to classify: #{e.message}"
  end

  private

  def classify_intent(text)
    # We use a simple prompt for the LLM
    prompt = <<~PROMPT
      Classifique a mensagem do usuário em UMA das seguintes categorias:
      #{CATEGORIES.join(', ')}

      Se não se encaixar claramente, responda 'outros'.
      Responda APENAS com o nome da categoria.

      Mensagem: "#{text}"
    PROMPT

    # Using the existing LLM infrastructure
    # We create a temporary safe agent config or just use direct LLM call if possible.
    # Since we are inside Captain, we can try to use RubyLLM direct client if configured,
    # or fallback to the conversation's assistant if available.

    # For simplicity and robustness in this specific codebase context, let's use the OpenAI client wrapper directly
    # if available via the Agents gem or RubyLLM configuration already set up.

    messages = [{ role: 'user', content: prompt }]

    # Robust API Key fetching for background jobs
    api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    api_key ||= ENV.fetch('OPENAI_API_KEY', nil)

    # Strip eventual image suffixes if present (reuse sanitization logic)
    api_key = api_key.to_s.gsub(/\.(png|jpg|jpeg|gif|webp|svg|@2x|@3x).*$/i, '').strip

    client = OpenAI::Client.new(access_token: api_key)

    response = client.chat(
      parameters: {
        model: 'gpt-4o-mini', # Cost effective
        messages: messages,
        temperature: 0.0,
        max_tokens: 10
      }
    )

    content = response.dig('choices', 0, 'message', 'content')
    content&.strip&.downcase
  end
end
