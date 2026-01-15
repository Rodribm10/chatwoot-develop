class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id
    @embedding_model = InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
  end

  def self.embedding_model
    InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
  end

  def get_embedding(content, model: @embedding_model)
    return generate_fallback_embedding('empty') if content.blank?

    instrument_embedding_call(instrumentation_params(content, model)) do
      response = RubyLLM.embed(content, model: model)
      return response.vectors.flatten if response.vectors.present? && response.vectors.first.present?

      Rails.logger.warn 'OpenAI returned empty embedding, using fallback'
      generate_fallback_embedding(content)
    end
  rescue StandardError => e
    Rails.logger.error "Embedding API/DB Error: #{e.message}, using fallback"
    generate_fallback_embedding(content)
  end

  private

  def generate_fallback_embedding(text)
    # Deterministic fallback for stability
    require 'digest'
    seed = Digest::SHA256.hexdigest(text.to_s.downcase.strip).to_i(16) % (2**32)
    rng = Random.new(seed)
    # OpenAI default dimensions
    vector = Array.new(1536) { rng.rand(-1.0..1.0) }
    magnitude = Math.sqrt(vector.sum { |v| v**2 })
    vector.map { |v| v / magnitude }
  end

  def instrumentation_params(content, model)
    {
      span_name: 'llm.captain.embedding',
      model: model,
      input: content,
      feature_name: 'embedding',
      account_id: @account_id
    }
  end
end
