---
name: creating-jasmine-tools
description: Defines the standard for creating Tools compatible with Jasmine (Captain AI) and the Agents gem. Use when the user needs to create a new Ruby tool class.
---

# Objetivo

Padronizar a criação de ferramentas no escopo `Captain::Tools` para garantir compatibilidade com `Agents::Tool`, `RubyLLM` e o sistema de injeção de dependência da Jasmine.

# Caminhos Padrão

- **Local principal:** `enterprise/lib/captain/tools/`
- **Alternativo (se service-heavy):** `enterprise/app/services/captain/tools/`

# Template Base

```ruby
module Captain
  module Tools
    class NomeDaSuaTool < Captain::Tools::BasePublicTool
      # Definir tool_name se for diferente do nome da classe (Opcional)
      # def name
      #   'nome_da_tool'
      # end

      def description
        'Descrição curta e objetiva do que a ferramenta faz. Isso é visível para a IA.'
      end

      # Definição de Parâmetros (DSL da gem Agents)
      param :parametro_um, type: 'string', desc: 'Descrição do parâmetro', required: true
      param :parametro_dois, type: 'integer', desc: 'Descrição do parâmetro opcional', required: false

      # Método principal de execução
      # tool_context: Objeto de contexto (pode conter estado da conversa)
      # kwargs: Argumentos passados pela IA já normalizados
      def perform(tool_context, **kwargs)
        # 1. Logging Inicial Padronizado
        Rails.logger.info "[#{self.class.name}] Iniciando execução. Params: #{kwargs.inspect}"

        # 2. Resolução de Dependências (Conversa/Contato)
        # O BasePublicTool já tenta popular @conversation e @user no initialize,
        # mas podemos garantir reload ou fallback aqui.
        ensure_context!(tool_context)

        return "Erro: Conversa não identificada." unless @conversation

        # 3. Lógica da Ferramenta
        parametro_um = kwargs[:parametro_um]

        result = executa_logica(parametro_um)

        # 4. Retorno
        # Sempre retornar String ou Hash serializável (JSON friendly)
        result
      rescue StandardError => e
        handle_error(e)
      end

      private

      def ensure_context!(tool_context)
        # Se @conversation não veio no initialize, tenta extrair do contexto
        if @conversation.nil? && tool_context.present?
             state = resolve_context(tool_context)
             @conversation = find_conversation(state)
        end
      end

      def executa_logica(dado)
        # Implementação...
        "Sucesso: #{dado}"
      end

      def handle_error(exception)
        Rails.logger.error "[#{self.class.name}] Erro: #{exception.message}"
        Rails.logger.error exception.backtrace.first(5).join("\n")
        "Ocorreu um erro técnico ao processar sua solicitação: #{exception.message}"
      end
    end
  end
end
```

# Checklist de Verificação

1. **Herança:** A classe herda de `Captain::Tools::BasePublicTool` (para tools públicas) ou `Captain::Tools::BaseTool`?
2. **Método `perform`:** Está implementando `perform` ao invés de apenas `execute` (para compatibilidade total com `Agents`)?
3. **Parâmetros:** Os parâmetros estão definidos com `param :nome, type: ...`? Isso ajuda a gerar o esquema JSON automaticamente para a LLM.
4. **Logging:** Existe log no início (`info`) e no rescue (`error`) com prefixo `[NomeClass]`?
5. **Contexto:** A ferramenta lida com o fato de `@conversation` poder ser nulo (ex: uso fora do fluxo web)?
6. **Retorno:** O retorno é texto ou JSON string (algo que a LLM possa ler)?

# Boas Práticas

- **Snake Case:** Nomes de arquivo em snake_case (ex: `check_availability_tool.rb`).
- **Nomes Claros:** O método `name` (ou o nome da classe inferido) deve ser claro (ex: `consultar_saldo` é melhor que `acao_banco`).
- **Idempotência:** Se possível, a ferramenta deve ser segura de rodar múltiplas vezes (ex: checar disponibilidade não altera estado, reservar altera - cuidado).
- **Tratamento de Erros:** Nunca deixe uma exception explodir para a LLM. Capture `StandardError` e retorne uma mensagem amigável de erro.
