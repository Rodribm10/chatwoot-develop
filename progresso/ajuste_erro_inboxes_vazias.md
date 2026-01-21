# Ajuste de erro: lista de inboxes vazia

**Problema**
- A pagina `/app/accounts/:id/settings/inboxes/list` ficava vazia.
- A requisicao `GET /api/v1/accounts/:id/inboxes` retornava **500**.

**Causa raiz**
- Erro em `Inbox#callback_webhook_url` quando `channel` estava `nil`.
- O Jbuilder `app/views/api/v1/models/_inbox.json.jbuilder` chama `callback_webhook_url`.
- Resultado: exception `undefined method 'phone_number' for nil`, quebrando o JSON e a UI.

**Correcao aplicada**
Arquivo: `app/models/inbox.rb`

```ruby
  def callback_webhook_url
    return nil if channel.blank?

    case channel_type
    when 'Channel::TwilioSms'
      "#{ENV.fetch('FRONTEND_URL', nil)}/twilio/callback"
    when 'Channel::Sms'
      return nil if channel.phone_number.blank?
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/sms/#{channel.phone_number.delete_prefix('+')}"
    when 'Channel::Line'
      return nil if channel.line_channel_id.blank?
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/line/#{channel.line_channel_id}"
    when 'Channel::Whatsapp'
      return nil if channel.phone_number.blank?
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{channel.phone_number}"
    end
  end
```

**Como validar**
1. Reinicie o servidor Rails.
2. Abra `/app/accounts/1/settings/inboxes/list`.
3. Verifique no console que `GET /api/v1/accounts/1/inboxes` retorna **200**.
4. Confirme que a lista de inboxes aparece.

**Observacao**
- Mensagens podem continuar chegando via webhook mesmo se a lista estiver vazia; isso indica falha apenas na renderizacao da API/JSON.

**Log de referencia**
```
Started GET "/api/v1/accounts/1/inboxes" for ::1 at 2026-01-21 09:13:52 -0300
Processing by Api::V1::Accounts::InboxesController#index as JSON
Completed 500 in 95ms
ActionView::Template::Error (undefined method 'phone_number' for nil)
app/models/inbox.rb:200:in `callback_webhook_url'
app/views/api/v1/models/_inbox.json.jbuilder:17
```
