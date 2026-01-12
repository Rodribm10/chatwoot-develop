# Feature: Webhook URL nas Configurações da Unidade

**Data:** 12/01/2026
**Autor:** Antigravity (Assistant)

## Objetivo

Permitir que cada Unidade (Hotel/Pousada) tenha seu próprio endpoint de webhook (ex: n8n) configurado via interface administrativa, para onde serão enviados os dados de novas reservas e atualizações de status.

## Contexto

Anteriormente, não havia um campo na interface para definir para onde os dados da reserva deveriam ser enviados após a confirmação do pagamento via Pix. Precisávamos de um campo `webhook_url` salvo junto com as configurações da unidade.

## Passos Realizados

1.  **Frontend (Vue.js):**

    - Arquivo: `app/javascript/dashboard/routes/dashboard/captain/units/UnitModal.vue`
    - Adicionado campo `webhook_url` no objeto `data`, `payload` e métodos `resetForm`.
    - Adicionado input visual na seção de configuração da modal.

2.  **Backend (Rails):**
    - Arquivo: `enterprise/app/controllers/api/v1/accounts/captain/units_controller.rb`
    - Atualizado `unit_params` para permitir o parâmetro `:webhook_url` através da API.

## Principais Arquivos Alterados

- `app/javascript/dashboard/routes/dashboard/captain/units/UnitModal.vue`
- `enterprise/app/controllers/api/v1/accounts/captain/units_controller.rb`

## Como Validar

1.  Acesse o Dashboard do Chatwoot -> Menu Captain -> Unidades.
2.  Clique em "Editar" em uma unidade existente ou "Nova Unidade".
3.  Role até o final do formulário. Deve haver um campo "Webhook URL".
4.  Insira uma URL (ex: `https://webhook.site/...`) e salve.
5.  Recarregue a página e abra a edição novamente para garantir que o valor persistiu.

## Como Reverter

- Reverter as alterações no `UnitModal.vue` removendo o campo do template e do script.
- Remover `:webhook_url` dos parâmetros permitidos no `UnitsController`.
