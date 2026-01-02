# Integração Nativa WuzAPI (V1 Final)

## Visão Geral

Integração 100% nativa do WuzAPI (Go) com o Chatwoot, eliminando a necessidade de n8n/Typebot. A solução suporta envio e recebimento de mensagens de texto, sincronização de mensagens do celular e automação de webhook.

## Conquistas Técnicas (V1.5)

### 1. Mensagens de Entrada (Inbound)

- **Parser Estrito**: Filtra e normaliza eventos do WuzAPI.
- **Deduplicação Inteligente**: Usa `Info.ID` para evitar mensagens duplicadas.
- **Tratamento de Loops**: Ignora eco de mensagens (`from_me`) se não for uma mensagem de sincronia.

### 2. Mensagens de Saída (Outbound) Fixado

- **Criptografia Real**: Tokens são armazenados com `encrypts` do Rails 7.
- **Autenticação Corrigida**:
  - Problema Anterior: O banco salvava o token em `encrypted_wuzapi_user_token` mas o Rails buscava em `wuzapi_user_token`.
  - Solução: Migração renomeou as colunas para o padrão do Rails (`wuzapi_user_token` contendo o dado criptografado).
- **Envio Confiável**: Headers de autenticação (`token: ...`) agora são gerados com o token decriptado corretamente.

### 3. Sincronia Mobile (Two-Way Sync)

- **Lógica de Espelhamento**: Mensagens enviadas pelo celular (App WhatsApp) são capturadas pelo Chatwoot.
- **Conversão de Tipo**: O sistema identifica `Info.IsFromMe == true` e converte para `message_type: :outgoing` e `sender: nil`.
- **Benefício**: Histórico completo da conversa, independente de onde foi enviada.

### 4. Automação (VPS Ready)

- **Configuração Automática de Webhook**:
  - Ao criar um canal WuzAPI, o sistema dispara `after_create_commit :setup_webhooks`.
  - Configura automaticamente a URL: `#{ENV['FRONTEND_URL']}/webhooks/whatsapp/#{phone_number}`.
  - Define `events: ['All']` no WuzAPI.

## Guia de Instalação (VPS / Portainer)

### Variáveis de Ambiente Necessárias

Certifique-se de que estas variáveis estejam no `.env` da VPS:

```bash
FRONTEND_URL=https://seu-chatwoot.com
# Chaves de Criptografia (Gere com `rake secret`)
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

### Passos de Deploy

1. **Pull Code**: Baixe a última versão.
2. **Migrations**: `bundle exec rails db:migrate` (Essencial para renomear colunas).
3. **Restart**: Reinicie os containers (`web` e `sidekiq`) para limpar caches de esquema.

### Troubleshooting Comum

| Sintoma                | Causa Provável             | Solução                                                                                 |
| ---------------------- | -------------------------- | --------------------------------------------------------------------------------------- |
| **Erro 401 no Envio**  | Token salvo incorretamente | Reinicie o app e re-salve o token do canal.                                             |
| **Mensagem não chega** | Webhook URL errada         | Verifique se `FRONTEND_URL` está correto. Use "Atualizar" no canal para forçar o setup. |
| **Duplicidade**        | Deduplicação falhando      | Verifique logs por "WuzAPI: Ignoring duplicate".                                        |
