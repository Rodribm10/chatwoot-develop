# Correção e Arquitetura: Delegação via Scenarios (Captain AI)

**Data:** 07/01/2026
**Contexto:** Correção do fluxo onde a agente principal (Jasmine) consulta sub-agentes (Scenarios) para obter informações especializadas sem transferir o atendimento.

---

### 1. O Problema Original

O sistema falhava ao tentar acionar a ferramenta de delegação `consultar_[cenario]`.
Os erros observados nos logs eram:

1.  **`ArgumentError: wrong number of arguments`**: A ferramenta esperava `keyword arguments` (`pergunta_interna:`), mas o `ToolRunner` enviava um objeto de contexto (`Agents::ToolContext`) e um hash de parâmetros.
2.  **`unknown keyword: :api_key`**: A chamada interna ao `RubyLLM` tentava passar a chave de API manualmente, mas a biblioteca não aceitava esse argumento (a configuração é global).
3.  **Retorno de Objeto Sujo**: A ferramenta retornava uma instância de `RubyLLM::Message` (ex: `#<RubyLLM::Message:0x...>`) para o agente principal, em vez do texto da resposta. Isso fazia com que a Jasmine não soubesse o que responder ao cliente.

**Ponto de Quebra:** Ocorria exatamente dentro do método `execute` da classe `ScenarioDelegatorTool`, tanto na entrada (assinatura do método) quanto na saída (retorno para a Jasmine).

---

### 2. Decisão de Arquitetura

**Modelo Escolhido: Delegação por Proxy (Tool)**

- **Não usamos Handoff:** Não transferimos o `contexto` da conversa para o sub-agente. O cliente **nunca** fala diretamente com a Daniela (Reservas).
- **Jasmine como Interface Única:** A Jasmine continua sendo a "dona" da conversa. Ela "vira para o lado", pergunta para a Daniela (via ferramenta), recebe a resposta técnica e a "traduz" ou repassa para o cliente com a voz dela.
- **Tool como Proxy:** A classe `ScenarioDelegatorTool` atua como um _wrapper_ que encapsula uma chamada LLM isolada. Para o sistema, é apenas uma ferramenta que retorna texto, igual a uma consulta de API.

---

### 3. O que foi Alterado

Arquivo principal: `enterprise/lib/captain/tools/scenario_delegator_tool.rb`

#### Antes (Quebrado)

```ruby
class ScenarioDelegatorTool < Agents::Tool
  def schema ... end # Definição manual de schema

  def execute(pergunta_interna:) # Assinatura incompatível com ToolRunner
    # Chamada incorreta com api_key
    RubyLLM::Chat.new(...).ask(..., api_key: ...)
    # Retorno implícito do objeto Message
  end
end
```

#### Depois (Correto)

```ruby
# 1. Herança correta para aproveitar a infraestrutura do projeto
class ScenarioDelegatorTool < Captain::Tools::BasePublicTool

  # 2. Uso da DSL padrão para definição de parâmetros
  param :pergunta_interna, type: 'string', desc: '...'

  # 3. Assinatura padrão 'perform' que recebe o contexto e args nomeados
  def perform(_tool_context, pergunta_interna:)

    # ... lógica de prompt ...

    # 4. Chamada RubyLLM sem api_key (usa config global do Runner)
    response = RubyLLM::Chat.new(model: assistant.send(:agent_model))
                            .ask(prompt)

    # 5. Extração explícita do conteúdo de texto
    response.respond_to?(:content) ? response.content : response.to_s
  rescue StandardError => e
    "Erro ao consultar departamento: #{e.message}"
  end
end
```

---

### 4. Fluxo Final (Estado Correto)

1.  **Detecção:** A `JasmineBrain` (ou o LLM principal) detecta que o usuário quer algo específico de um cenário (ex: "quero reservar").
2.  **Decisão:** O LLM decide chamar a ferramenta `consultar_daniela_reservas` com o argumento `pergunta_interna="cliente quer reservar para semana que vem"`.
3.  **Execução (ToolRunner):**
    - Instancia `ScenarioDelegatorTool`.
    - Seta a API Key do assistente globalmente no `RubyLLM` (via `AgentRunnerService`).
    - Chama `perform`.
4.  **Sub-agente (Proxy):**
    - A ferramenta monta um prompt "Você é Daniela..." com a pergunta da Jasmine.
    - Chama o LLM (síncrono).
5.  **Retorno:** A ferramenta devolve **apenas a string** com a resposta da Daniela (ex: "Para reservar, use o link X...").
6.  **Resposta ao Cliente:** A Jasmine recebe essa string como `tool_output`, incorpora ao contexto e gera a resposta final para o WhatsApp do cliente.

---

### 5. Pegadinhas (O que NÃO fazer)

1.  **NUNCA implementar `execute` manualmente** em ferramentas que herdam de `BasePublicTool`. O método `perform` é o contrato correto que recebe tratamento de erros e logs.
2.  **NUNCA passar `api_key` para o método `ask` do RubyLLM.** O `AgentRunnerService` gerencia a chave através de `Agents.configure` ou `RubyLLM.config`. Passar manualmente gera erro de argumento.
3.  **CUIDADO com o retorno do LLM.** O `RubyLLM` retorna objetos complexos. Sempre extraia `.content` ou `.to_s` antes de devolver para o agente principal, senão o agente "alucina" com o ID do objeto Ruby.

---

### 6. Como Validar

Nos logs da aplicação (`docker logs` ou console):

1.  Procure por `[DEBUG V2] Running with agents: jasmine`.
2.  Veja o `Agent result`.
3.  Dentro de `messages`, localize o item com `role: :tool`.
4.  **Verificação de Sucesso:** O `content` da tool deve ser um **texto legível** (ex: "O link é...") e **NÃO** algo como `#<RubyLLM::Message...>`.
5.  Se houver erro, aparecerá em `error: ...` no log do `Agent result`.
