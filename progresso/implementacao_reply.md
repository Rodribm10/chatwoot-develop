# Implementação do Suporte Nativo a Reply

## Objetivo

Migrar o sistema de respostas (relacionamento entre mensagens) de um campo flexível no JSON `content_attributes` para uma relação nativa no banco de dados usando a coluna `in_reply_to_id`.

## Contexto

O Chatwoot estava utilizando o campo `content_attributes['in_reply_to']` para armazenar o ID da mensagem respondida. Para seguir as melhores práticas solicitadas pelo arquiteto, implementamos uma relação `belongs_to` direta, garantindo maior integridade e performance.

## Passos Realizados

1.  **Criação da Migration**: Adição da coluna `in_reply_to_id` na tabela `messages` com chave estrangeira e índice.
2.  **Atualização do Modelo `Message`**:
    - Inclusão da associação `belongs_to :in_reply_to`.
    - Remoção do acessório `in_reply_to` do `store :content_attributes` para evitar conflitos.
3.  **Refatoração do `InReplyToMessageBuilder`**: Atualização do builder central para preencher o novo campo.
4.  **Ajuste no `IncomingMessageWuzapiService`**: Mapeamento do `WAID` recebido via Wuzapi para o ID interno da mensagem e preenchimento da relação.
5.  **Atualização da API**: Inclusão do campo `in_reply_to_id` no partial de serialização das mensagens.
6.  **Ajuste no Frontend**:
    - `MessageList.vue`: Atualizado para detectar `inReplyToId`.
    - `Base.vue`: Refatorado para exibir o preview da mensagem citada de forma robusta.

## Códigos e Arquivos Alterados

- `db/migrate/20260124190000_add_in_reply_to_id_to_messages.rb`
- `app/models/message.rb`
- `app/services/messages/in_reply_to_message_builder.rb`
- `app/services/whatsapp/incoming_message_wuzapi_service.rb`
- `app/views/api/v1/models/_message.json.jbuilder`
- `app/javascript/dashboard/components-next/message/MessageList.vue`
- `app/javascript/dashboard/components-next/message/bubbles/Base.vue`

## Como Validar ou Reverter

- **Validar**:
  - Rodar `bin/rails db:migrate`.
  - Receber ou enviar uma resposta e verificar se `Message.last.in_reply_to_id` está preenchido.
  - Verificar no dashboard se o balão de resposta aparece com o preview correto.
- **Reverter**:
  - Rodar `bin/rails db:rollback`.
  - Reverter as alterações nos arquivos alterados.

## Variáveis de Ambiente

Nenhuma variável de ambiente adicional é necessária.
