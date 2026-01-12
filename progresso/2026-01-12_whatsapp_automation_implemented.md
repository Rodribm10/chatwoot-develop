# Automação de WhatsApp Implementada (12/01/2026)

## Funcionalidades Entregues

1.  **Vínculo Unidade -> Inbox (WhatsApp)**

    - Adicionado campo `inbox_id` na tabela `captain_units`.
    - **Interface**: No painel de Unidades, agora é possível selecionar qual "Caixa de Entrada" enviará as notificações automáticas.

2.  **Serviço de Notificação (`Captain::WhatsappNotificationService`)**

    - Formata a mensagem automaticamente.
    - Usa o canal da unidade para enviar a mensagem.
    - Verifica se o cliente já possui conversa no canal alvo; se não, cria automaticamente.

3.  **Integração com Pagamento Pix**
    - Assim que o Banco Inter confirma o pagamento via Webhook, o sistema dispara a mensagem de confirmação.

## Como Testar

1.  Acesse o **Painel Admin > Unidades**.
2.  Edite uma unidade e **Selecione o Inbox** correspondente ao WhatsApp que deve enviar as mensagens.
3.  Faça uma reserva no fluxo público (`/public/accounts/...`).
4.  Realize o pagamento (ou simule via Console/Script).
5.  O cliente receberá uma mensagem:
    > "Olá {nome}, confirmamos o pagamento da sua reserva..."

## Arquivos Criados/Modificados

- `db/migrate/..._add_inbox_id_to_captain_units.rb`
- `enterprise/app/models/captain/unit.rb`
- `enterprise/app/controllers/api/v1/accounts/captain/units_controller.rb`
- `app/javascript/dashboard/routes/dashboard/captain/units/UnitModal.vue`
- `enterprise/app/services/captain/whatsapp_notification_service.rb`
- `enterprise/app/controllers/public/api/v1/captain/webhooks_controller.rb`
