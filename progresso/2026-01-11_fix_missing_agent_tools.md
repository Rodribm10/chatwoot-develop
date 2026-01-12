# Fix: Missing Built-in Agent Tools (ReactToMessage)

## Sintoma

O usuário relatou que o Assistente Captain AI respondia com texto (ex: "Valeu!") em vez de usar a ferramenta `react_to_message` (reação com emoji), mesmo com a ferramenta ativada na interface.

## Análise

1.  Os logs mostraram que o agente recebia a mensagem e gerava uma resposta de texto (`ResponseBuilderJob` funcionava).
2.  A ferramenta `react_to_message` existe em `tools.yml` e no código (`Captain::Tools::ReactToMessageTool`).
3.  **Causa Raiz:** A classe `Captain::Assistant` (método `agent_tools`) carregava apenas ferramentas _hardcoded_ (`faq_lookup`, `handoff`) e ferramentas personalizadas (`HttpTool`). Ela **ignorava** todas as outras ferramentas nativas ativadas via `ToolConfig` (como `react_to_message`).

## Solução Aplicada

Modificado `enterprise/app/models/captain/assistant.rb` para carregar dinamicamente as ferramentas:

```ruby
    # Before
    tools = [
      self.class.resolve_tool_class('faq_lookup').new(self),
      self.class.resolve_tool_class('handoff').new(self)
    ]
    # ...load scenarios...
    # ...load custom tools...

    # After
    # ...
    # Add enabled built-in tools
    tool_configs.where(is_enabled: true).each do |tool_config|
      tool_class = self.class.resolve_tool_class(tool_config.tool_key)
      next unless tool_class
      tools << tool_class.new(self) unless tools.any? { |t| t.is_a?(tool_class) }
    end
    # ...
```

## Como Validar

1.  Faça o deploy/restart da aplicação.
2.  Garanta que a ferramenta "Reagir a Mensagens" esteja habilitada na UI do assistente.
3.  Envie uma mensagem de agradecimento ("Obrigado", "Valeu") como cliente.
4.  O agente agora deve ter acesso à ferramenta e poderá optar por usá-la.

## Notas Adicionais

- O erro `relation "installation_configs" does not exist` observado nos logs parece ser um problema de ordem de inicialização ou migração pendente no ambiente do usuário, mas não bloqueia a execução principal se o servidor inicia.
