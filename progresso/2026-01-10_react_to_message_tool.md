# Implementação: Ferramenta de Reação de Mensagem (Captain AI)

**Data:** 10/01/2026  
**Objetivo:** Permitir que o Captain reaja às mensagens do cliente com emojis, simulando comportamento humano.

---

## Contexto

No N8N, a reação é feita via API externa usando IDs dinâmicos (`account_id`, `conversation_id`, `message_id`). No Captain, esses dados já estão disponíveis no contexto interno, então criamos uma tool nativa.

---

## Arquivos Criados/Modificados

### [NOVO] `enterprise/app/services/captain/tools/react_to_message_tool.rb`

- Tool que reage à última mensagem incoming do cliente
- Parâmetro: `emoji` (string)
- Cria mensagem com `is_reaction: true` e `in_reply_to: source_id`

### [MODIFICADO] `enterprise/app/services/captain/llm/assistant_chat_service.rb`

- Adicionada no método `build_tools`:

```ruby
Captain::Tools::ReactToMessageTool.new(@assistant, user: nil, conversation: @conversation)
```

### [MODIFICADO] `enterprise/app/services/captain/tools/definitions.rb`

- Adicionada definição para aparecer em "Poderes":

```ruby
'react_to_message' => {
  type: :internal,
  name: 'Reagir a Mensagens',
  description: 'React to customer messages with emoji (👍, ❤️, 😊)'
}
```

---

## Como Funciona

1. **Agent decide reagir** → Chama `react_to_message(emoji: "👍")`
2. **Tool executa**:
   - Pega `conversation` do contexto
   - Busca última mensagem incoming (`messages.incoming.last`)
   - Pega `source_id` (ID externo do WhatsApp)
   - Cria mensagem com `is_reaction: true`
3. **SendReplyJob** → Detecta `is_reaction` → Chama `send_reaction_message`
4. **Wuzapi Client** → `POST /chat/react` com Phone, Id e Body (emoji)

---

## Configuração de Uso (Prompt)

Adicionar no prompt do assistente:

```
## Uso de Reações

Use a ferramenta `react_to_message` para:
- Reagir com 👍 quando o cliente confirmar algo positivo
- Reagir com ❤️ quando o cliente agradecer
- Reagir com 😊 para demonstrar empatia
- Reagir com 🙏 quando receber elogios

NÃO use reações:
- Em mensagens de reclamação
- Quando o cliente estiver irritado
```

---

## Ativação

1. Acessar: Captain → Assistentes → [Assistente] → Poderes
2. Ativar "Reagir a Mensagens"
3. (Opcional) Adicionar instruções no prompt do assistente

---

## Validação

- Testar no Playground: _"reaja positivamente"_
- Testar via WhatsApp: enviar mensagem positiva e verificar reação
