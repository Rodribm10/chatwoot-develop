# Correção de Erro 500 na Conexão Wuzapi

**Data:** 01/01/2026
**Responsável:** Antigravity (IA)

## Objetivo

Corrigir o erro "500 Internal Server Error" que ocorria ao tentar conectar uma caixa de entrada Wuzapi (clicar em "Conectar" ou visualizar QR Code), impedindo a exibição do QR Code.

## Contexto

O controlador `Api::V1::Accounts::Inboxes::WuzapiController` tentava recuperar o token de autenticação do usuário (`wuzapi_user_token`) a partir do hash `provider_config` do canal. No entanto, por questões de segurança, o modelo `Channel::Whatsapp` (no backend) move esse token para um atributo criptografado dedicado (`encrypted_wuzapi_user_token`) logo após a criação/atualização, removendo-o do `provider_config`.

Como resultado, o controlador sempre encontrava um token `nil` ao buscar no local antigo, levantando uma exceção "Token Wuzapi ausente" que resultava no erro 500.

## Passos Realizados

1.  **Análise de Logs:** Identificado erro 500 e mensagem de log `Wuzapi Token Missing for Inbox X`.
2.  **Análise de Código:** Verificado `wuzapi_controller.rb` e `channel/whatsapp.rb`.
3.  **Identificação da Causa:** Confirmado que o token não reside mais em `provider_config`.
4.  **Correção:** Alterado o método `user_token` no controlador para ler do atributo correto.

## Arquivos Alterados

### `app/controllers/api/v1/accounts/inboxes/wuzapi_controller.rb`

```ruby
# Antes
def user_token
  token = @inbox.channel.provider_config['wuzapi_user_token']
  # ...
end

# Depois
def user_token
  token = @inbox.channel.wuzapi_user_token
  # ...
end
```

## API Calls / Variáveis de Ambiente

- Nenhuma variável de ambiente foi alterada.
- O endpoint afetado foi `POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/wuzapi/connect` e `GET .../qr`.

## Como Validar

1.  Acessar o Chatwoot -> Configurações -> Caixas de Entrada -> [Wuzapi Inbox].
2.  Clicar na aba de configuração do Wuzapi.
3.  O QR Code deve ser gerado e exibido imediatamente (ou status de conectado), sem erro 500 no console/network.

## Como Reverter

Se necessário, reverter a alteração no arquivo `app/controllers/api/v1/accounts/inboxes/wuzapi_controller.rb` voltando a leitura para `@inbox.channel.provider_config['wuzapi_user_token']`.
