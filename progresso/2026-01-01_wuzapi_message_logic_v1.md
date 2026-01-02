# WuzAPI Message Handling Logic (V1.5)

## Objetivo

Documentar a lógica de tratamento de mensagens do WuzAPI, focando no mecanismo "híbrido" que permite:

1.  **Mensagens de Clientes (Inbound):** Recebimento padrão, criando conversas e atribuindo ao contato.
2.  **Sincronização via Celular (Sync):** Mensagens enviadas pelo próprio aparelho físico aparecem no Chatwoot como "Enviadas" (outgoing), mantendo o histórico consistente.

---

## 1. O Desafio (Identidade do Remetente)

No WhatsApp, quando você envia uma mensagem pelo celular, o webhook chega com `from_me: true`.
O problema é que o campo `Info.Sender` (quem enviou) é você mesmo. Se usarmos isso para buscar a conversa, o Chatwoot tentaria achar uma conversa com o seu próprio número, o que está errado.

**Solução:** Precisamos inverter a lógica para buscar "com quem estou falando" quando a mensagem parte de mim.

## 2. A Solução (Código)

### A. Parser Inteligente (`provider/wuzapi/payload_parser.rb`)

Esta é a classe que normaliza os dados brutos do WuzAPI para o Chatwoot entender.

**Lógica de Identificação do Remetente (`sender_phone_number`):**

```ruby
def sender_phone_number
  jid = if from_me?
          # SE fui eu que enviei (celular), o "dono" da conversa é o DESTINATÁRIO (Chat)
          params.dig(:event, :Info, :Chat)
        else
          # SE foi o cliente, o "dono" é o REMETENTE (Sender)
          params.dig(:event, :Info, :Sender)
        end
  # ... remove sufixo @s.whatsapp.net
end
```

Isso garante que, mesmo quando você envia do celular, o Chatwoot sabe que aquela mensagem pertence à conversa com o Cliente X.

### B. Serviço de Entrada (`incoming_message_wuzapi_service.rb`)

Este serviço decide como gravar a mensagem no banco de dados.

**Lógica de Tipo de Mensagem:**

```ruby
def create_message(parser, conversation)
  is_outgoing = parser.from_me? # Verdadeiro se veio do celular

  conversation.messages.create!(
    # ...
    message_type: is_outgoing ? :outgoing : :incoming, # Define a cor do balão (Azul/Branco)
    sender: is_outgoing ? nil : @contact,              # Se outgoing, sender é nil (Sistema/Agente). Se incoming, é o Contato.
    # ...
  )
end
```

## 3. Fluxo Comparativo

| Cenário           | Origem Real        | `from_me?` | Identificador Usado (`sender_phone_number`) | Tipo no Chatwoot | Resultado Visual        |
| :---------------- | :----------------- | :--------- | :------------------------------------------ | :--------------- | :---------------------- |
| **Cliente envia** | Celular do Cliente | `false`    | `Info.Sender` (O Cliente)                   | `:incoming`      | Balão Branco (Esquerda) |
| **Você envia**    | Seu Celular Físico | `true`     | `Info.Chat` (O Cliente)                     | `:outgoing`      | Balão Azul (Direita)    |
| **Agente envia**  | Painel Chatwoot    | N/A        | N/A (Via API Outbound)                      | `:outgoing`      | Balão Azul (Direita)    |

## 4. Conclusão

Essa arquitetura permite que o Chatwoot funcione como um espelho fiel do WhatsApp, aceitando operações mistas (painel + celular físico) sem perder o contexto da conversa ou criar contatos duplicados errados.
