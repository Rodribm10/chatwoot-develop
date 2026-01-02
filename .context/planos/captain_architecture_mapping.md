# Relatório de Mapeamento da Arquitetura do Capitão (Fase 1)

## 1. Visão Geral do Pipeline

O fluxo de mensagens do Capitão é orquestrado pelo Job `Captain::Conversation::ResponseBuilderJob`.
Este Job decide qual pipeline executar com base na flag `captain_integration_v2`.

- **Entrada (Trigger)**: `ResponseBuilderJob.perform(conversation, assistant)`
- **Pipeline V1 (Ativo)**: `Captain::Llm::AssistantChatService`
- **Pipeline V2 (Futuro/Agente)**: `Captain::Assistant::AgentRunnerService`

Como a implementação deve ser segura e incremental, focaremos na extensão do **Pipeline V1** (`AssistantChatService`), que é a estrutura padrão atual.

## 2. Pontos de Extensão Identificados

### A. Ponto de Entrada da Mensagem

**Arquivo**: `enterprise/app/services/captain/llm/assistant_chat_service.rb`
**Método**: `generate_response(additional_message:, message_history:, role:)`

Este é o local ideal para injetar a `JasmineBrain`. Antes de chamar `request_chat_completion`, podemos passar a mensagem e o histórico pelo cérebro da Jasmine.

```ruby
# Exemplo Conceitual
def generate_response(...)
  # 1. Brain Decision Layer
  brain_decision = Captain::Llm::JasmineBrain.decide(
    message: additional_message,
    history: message_history,
    assistant: @assistant
  )

  # 2. Execute Decision
  if brain_decision.strategy == :tool
    # Executa ferramenta e alimenta LLM com resultado
  elsif brain_decision.strategy == :rag_required
    # Busca contexto e força prompt RAG
  else
    # Segue fluxo normal (Direct Response)
    super
  end
end
```

### B. Montagem do Prompt Final

**Arquivo**: `enterprise/app/helpers/captain/chat_helper.rb`
**Método**: `request_chat_completion` e `build_chat`

O `ChatHelper` (incluído no Service) é quem efetivamente constrói o objeto `chat` e chama o `RubyLLM`.

- `setup_system_instructions` monta o system prompt.
- `setup_tools` anexa as ferramentas nativas.

Se precisarmos modificar drasticamente o Prompt Final (para incluir Output Normalizado da Jasmine), precisaremos ou sobrescrever métodos do `ChatHelper` ou manipular o array `@messages` dentro do `AssistantChatService` antes de chamar `request_chat_completion`.

### C. Execução de Ferramentas

Hoje, o Capitão usa "function calling" nativo do Agente (`ChatHelper#setup_tools`).
A Jasmine propõe executar ferramentas **antes** do LLM ("Brain Layer").
Isso significa que o `JasmineBrain` pode retornar um "Resultado de Ferramenta" que será inserido no contexto como uma mensagem de sistema ou função, para que o LLM apenas formate a resposta final.

## 3. Plano de Arquivos (Fase 2)

Arquivos a criar/modificar:

1.  **[NOVO]** `enterprise/app/services/captain/llm/jasmine_brain.rb`
    - Contém `IntentDetector` e `StrategyDecider`.
2.  **[MODIFICAR]** `enterprise/app/services/captain/llm/assistant_chat_service.rb`
    - Injetar chamada ao `JasmineBrain` em `generate_response`.
3.  **[NOVO]** `enterprise/app/services/captain/tools/definitions.rb`
    - Definições das ferramentas Jasmine.

## Conclusão

O mapeamento confirma que é viável injetar a lógica da Jasmine no `AssistantChatService` sem quebrar a estrutura existente. A "Brain Layer" atuará como um middleware inteligente antes da chamada final ao LLM.
