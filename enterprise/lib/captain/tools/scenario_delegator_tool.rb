# enterprise/lib/captain/tools/scenario_delegator_tool.rb
module Captain::Tools
  class ScenarioDelegatorTool < Captain::Tools::BasePublicTool
    attr_reader :scenario

    def initialize(scenario, user: nil, conversation: nil)
      @scenario = scenario
      super(@scenario.assistant, user: user, conversation: conversation)
    end

    def name
      "consultar_#{@scenario.title.parameterize.underscore}"
    end

    def description
      "Consulta o departamento especializado: #{@scenario.description}. Use esta ferramenta para obter informações ou realizar ações sobre este assunto."
    end

    param :pergunta_interna, type: 'string', desc: 'A pergunta ou instrução detalhada que você quer enviar para este departamento.'

    def perform(_tool_context, args = {})
      pergunta_interna = args[:pergunta_interna] || args['pergunta_interna']

      # Instanciamos o agente do cenário, que já carrega suas próprias ferramentas (custom tools, etc)
      agent = @scenario.agent(user: @user, conversation: @conversation)

      # Usamos o Runner padrão (Agents gem) para permitir o loop de Pensamento/Ação
      # Isso permite que este sub-agente decida se precisa chamar ferramentas ou apenas responder
      Rails.logger.info "[ScenarioDelegatorTool] Iniciando sub-agente: #{@scenario.title}"
      Rails.logger.info "[ScenarioDelegatorTool] Ferramentas do Agente (#{@scenario.title}): #{agent.tools.map(&:name)}"

      runner = Agents::Runner.with_agents(agent)

      result = runner.run(pergunta_interna, max_turns: 10)

      Rails.logger.info "[ScenarioDelegatorTool] Sub-agente (#{@scenario.title}) finished. Output: #{result.output.inspect}"

      if result.failed? || result.output.nil?
        Rails.logger.info "[ScenarioDelegatorTool] Falha no sub-agente (#{@scenario.title}):"
        # Agents::RunResult names: failed?, error, messages
        Rails.logger.info "  - Error: #{result.error}"
        Rails.logger.info "  - Last Messages: #{result.messages.last(3).map { |m| m.slice(:role, :content, :tool_calls) }.inspect}"
        return "O departamento #{@scenario.title} encontrou um erro: #{result.error || 'sem resposta clara'}."
      end

      result.output.is_a?(Hash) ? (result.output['response'] || result.output.to_s) : result.output.to_s
    rescue StandardError => e
      Rails.logger.error "[ScenarioDelegatorTool] ERRO CRÍTICO no sub-agente #{@scenario.title}: #{e.message}"
      if e.respond_to?(:record) && e.record
        Rails.logger.error "[ScenarioDelegatorTool] Invalid Record Class: #{e.record.class.name}"
        Rails.logger.error "[ScenarioDelegatorTool] Invalid Record Errors: #{e.record.errors.full_messages.inspect}"
        Rails.logger.error "[ScenarioDelegatorTool] Invalid Record Attributes: #{e.record.attributes.inspect}"
      end
      Rails.logger.error "[ScenarioDelegatorTool] Backtrace:\n#{e.backtrace.first(15).join("\n")}"
      "Erro técnico ao consultar o departamento #{@scenario.title}: #{e.message}"
    end
  end
end
