# enterprise/lib/captain/tools/scenario_delegator_tool.rb
module Captain::Tools
  class ScenarioDelegatorTool < Captain::Tools::BasePublicTool
    attr_reader :scenario

    def initialize(scenario)
      @scenario = scenario
      super(@scenario.assistant)
    end

    def name
      "consultar_#{@scenario.title.parameterize.underscore}"
    end

    def description
      "Consulta o departamento especializado: #{@scenario.description}. Use esta ferramenta para obter informações ou realizar ações sobre este assunto."
    end

    param :pergunta_interna, type: 'string', desc: 'A pergunta ou instrução detalhada que você quer enviar para este departamento.'

    def perform(_tool_context, pergunta_interna:)
      # Instanciamos o agente do cenário, que já carrega suas próprias ferramentas (custom tools, etc)
      agent = @scenario.agent

      # Usamos o Runner padrão (Agents gem) para permitir o loop de Pensamento/Ação
      # Isso permite que este sub-agente decida se precisa chamar ferramentas ou apenas responder
      Rails.logger.info "[ScenarioDelegatorTool] Iniciando sub-agente: #{@scenario.title}"
      Rails.logger.info "[ScenarioDelegatorTool] Ferramentas do Agente (#{@scenario.title}): #{agent.tools.map(&:name)}"

      runner = Agents::Runner.with_agents(agent)

      result = runner.run(pergunta_interna, max_turns: 10)

      Rails.logger.info "[ScenarioDelegatorTool] Sub-agente (#{@scenario.title}) finished. Output: #{result.output.inspect}"

      # Log steps to debug why tool might not have been called
      Rails.logger.info "[ScenarioDelegatorTool] Thoughts: #{result.thoughts.inspect}" if result.respond_to?(:thoughts)

      # Extraímos a resposta final (mesma lógica do AgentRunnerService)
      result.output['response'] || result.output.to_s
    rescue StandardError => e
      Rails.logger.error "[ScenarioDelegatorTool] Erro no sub-agente #{@scenario.title}: #{e.message}"
      "Erro ao consultar o departamento #{@scenario.title}: #{e.message}"
    end
  end
end
