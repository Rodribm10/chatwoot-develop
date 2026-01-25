class Jasmine::BrainService
  # Default intent keywords for hotel/motel business
  DEFAULT_INTENT_KEYWORDS = {
    price_question: %w[preço valor quanto custa fica tabela promoção pernoite diária],
    info_request: %w[como funciona detalhe explica suíte quarto tipo],
    policy: %w[horário check-in check-out política regra pagamento cancelamento],
    greeting: %w[oi olá bom dia boa tarde boa noite],
    objection: %w[caro não sei preciso pensar depois conversar],
    closing: %w[reservar agendar confirmar fechar quero sim pode],
    general: [] # fallback
  }.freeze

  # Strategies for handling intents
  RAG_MANDATORY = %i[price_question info_request policy].freeze
  RAG_OPTIONAL = %i[objection general].freeze
  RAG_PROHIBITED = %i[greeting closing].freeze

  attr_reader :inbox, :conversation, :message, :config

  def initialize(inbox:, conversation:, message:)
    @inbox = inbox
    @conversation = conversation
    @message = message
    @config = load_config
  end

  def respond
    trigger_media_analysis if message.attachments.any?
    llm_content = message.content_for_llm

    intent = IntentDetector.new(llm_content, intent_keywords).detect
    strategy = StrategyDecider.new(intent, jasmine_state).decide

    rag_context = fetch_rag_if_needed(strategy, llm_content)

    prompt = PromptAssembler.new(
      config: config,
      state: jasmine_state,
      history: recent_history,
      rag_context: rag_context,
      current_message: llm_content
    ).assemble

    response = call_llm(prompt)

    StateUpdater.new(conversation, intent, rag_context.present?).update

    log_decision(intent, strategy, rag_context)

    response
  rescue StandardError => e
    Rails.logger.error "[Jasmine::Brain] Error: #{e.message}"
    'Desculpe, tive um problema. Pode repetir?'
  end

  private

  def load_config
    inbox.jasmine_inbox_config || Jasmine::InboxConfig.new(
      rag_distance_threshold: ENV.fetch('DEFAULT_JASMINE_DISTANCE_THRESHOLD', 0.35).to_f,
      rag_max_results: 3,
      model: ENV.fetch('JASMINE_LLM_MODEL', 'gpt-4o-mini'),
      temperature: 0.7
    )
  end

  def intent_keywords
    custom = config.intent_keywords.presence || {}
    DEFAULT_INTENT_KEYWORDS.merge(custom.deep_symbolize_keys)
  end

  def jasmine_state
    conversation.custom_attributes&.dig('jasmine_state') || {}
  end

  def recent_history
    msgs = conversation.messages

    # Handle both ActiveRecord relations and arrays (for playground testing)
    return [] unless msgs.respond_to?(:where)

    msgs
      .where(message_type: %w[incoming outgoing])
      .order(created_at: :desc)
      .limit(4) # 2 pairs of messages
      .reverse
      .map { |m| { role: m.message_type == 'incoming' ? 'user' : 'assistant', content: m.content } }
  end

  def fetch_rag_if_needed(strategy, query)
    return nil if strategy == :no_rag
    return nil if loop_protection_triggered?

    results = Jasmine::SemanticSearchService.new(inbox).search(query, limit: config.rag_max_results)

    return nil if results.empty?

    results.map { |r| r[:content] || r.content }.join("\n\n---\n\n")
  end

  def loop_protection_triggered?
    (jasmine_state['rag_queries_count'] || 0) > 5
  end

  def fallback_response
    nil # Will trigger "vou verificar com a equipe"
  end

  def call_llm(prompt)
    chat = RubyLLM.chat(model: config.model).with_temperature(config.temperature)
    response = chat.ask(prompt)
    response.content
  end

  def log_decision(intent, strategy, rag_context)
    Rails.logger.info "[Jasmine::Brain] Intent: #{intent}, Strategy: #{strategy}, RAG: #{rag_context.present? ? 'yes' : 'no'}"
  end

  def trigger_media_analysis
    Rails.logger.info "[Jasmine::Brain] Triggering Media Analysis for Message #{message.id}"
    Jasmine::MediaAnalyzerService.new(message: message).perform
    message.attachments.reload # CRITICAL: Ensure we see the new metadata
    Rails.logger.info "[Jasmine::Brain] Media Analysis Completed for Message #{message.id}"
  rescue StandardError => e
    Rails.logger.error "[Jasmine::Brain] Media analysis failed: #{e.message}"
  end

  # =========================================
  # COMPONENT: Intent Detector
  # =========================================
  class IntentDetector
    attr_reader :text, :keywords

    def initialize(text, keywords)
      @text = text.to_s.downcase.strip
      @keywords = keywords
    end

    def detect
      # Check each intent type for keyword matches
      keywords.each do |intent_type, words|
        next if words.empty?
        return intent_type if words.any? { |word| text.include?(word.downcase) }
      end

      :general # fallback
    end
  end

  # =========================================
  # COMPONENT: Strategy Decider
  # =========================================
  class StrategyDecider
    attr_reader :intent, :state

    def initialize(intent, state)
      @intent = intent
      @state = state
    end

    def decide
      return :no_rag if RAG_PROHIBITED.include?(intent)
      return :rag_required if RAG_MANDATORY.include?(intent)

      :rag_optional
    end
  end

  # =========================================
  # COMPONENT: Prompt Assembler
  # =========================================
  class PromptAssembler
    MAX_HISTORY_MESSAGES = 4 # 2 pairs

    attr_reader :config, :state, :history, :rag_context, :current_message

    def initialize(config:, state:, history:, rag_context:, current_message:)
      @config = config
      @state = state
      @history = history.last(MAX_HISTORY_MESSAGES)
      @rag_context = rag_context
      @current_message = current_message
    end

    def assemble
      parts = []

      # System Prompt (identity, tone, rules)
      parts << "[INSTRUÇÕES DO SISTEMA]\n#{config.system_prompt}" if config.system_prompt.present?

      # Playbook SDR (sales script)
      parts << "[PLAYBOOK SDR]\n#{config.playbook_prompt}" if config.playbook_prompt.present?

      # Lead State
      if state.present?
        state_text = format_state(state)
        parts << "[ESTADO DO LEAD]\n#{state_text}"
      end

      # RAG Context (SOURCE OF TRUTH)
      if rag_context.present?
        parts << <<~RAG
          [CONTEXTO DA BASE DE CONHECIMENTO - FONTE DA VERDADE]
          Use EXCLUSIVAMENTE as informações abaixo para responder.
          NÃO invente ou complemente com conhecimento externo.

          #{rag_context}
        RAG
      end

      # History (limited)
      if history.present?
        history_text = history.map { |h| "#{h[:role] == 'user' ? 'Cliente' : 'Jasmine'}: #{h[:content]}" }.join("\n")
        parts << "[HISTÓRICO RECENTE]\n#{history_text}"
      end

      # Current message
      parts << "[MENSAGEM ATUAL DO CLIENTE]\n#{current_message}"

      parts.join("\n\n")
    end

    private

    def format_state(state)
      lines = []
      lines << "Etapa: #{state['stage']}" if state['stage']
      lines << "Qualificado: #{state['qualified'] ? 'Sim' : 'Não'}" if state.key?('qualified')

      if state['collected_info'].present?
        state['collected_info'].each do |key, value|
          lines << "#{key.capitalize}: #{value}"
        end
      end

      lines.join("\n")
    end
  end

  # =========================================
  # COMPONENT: State Updater
  # =========================================
  class StateUpdater
    MAX_STATE_SIZE = 4096 # 4KB

    attr_reader :conversation, :intent, :rag_used

    def initialize(conversation, intent, rag_used)
      @conversation = conversation
      @intent = intent
      @rag_used = rag_used
    end

    def update
      current_state = conversation.custom_attributes&.dig('jasmine_state') || {}

      new_state = current_state.merge(
        'last_intent' => intent.to_s,
        'rag_queries_count' => (current_state['rag_queries_count'] || 0) + (rag_used ? 1 : 0),
        'updated_at' => Time.current.iso8601
      )

      # Size protection
      if new_state.to_json.bytesize > MAX_STATE_SIZE
        Rails.logger.warn '[Jasmine::Brain] State too large, cleaning up'
        new_state = {
          'last_intent' => intent.to_s,
          'rag_queries_count' => 0,
          'updated_at' => Time.current.iso8601
        }
      end

      conversation.update!(
        custom_attributes: (conversation.custom_attributes || {}).merge('jasmine_state' => new_state)
      )
    end

    def self.cleanup(conversation)
      attrs = conversation.custom_attributes || {}
      attrs.delete('jasmine_state')
      conversation.update!(custom_attributes: attrs)
    end
  end
end
