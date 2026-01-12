# Handoff Webhook Implementation - Progress Log

## Data: 2026-01-11

### Objetivo

Implementar sistema de notificação via webhook quando o Captain AI escala conversas para atendimento humano, conforme Fase 1 do plano aprovado.

### Contexto

O usuário precisa notificar sistemas externos (CRM, telefonia, etc.) quando uma conversa é escalada. O webhook deve enviar:

- Dados do contato (nome, telefone, email)
- Contexto da escalação (motivo, sentimento, resumo)
- Informações da conversa e assistente

### Passos Executados

#### 1. Database Migration ✅

**Arquivo:** `db/migrate/20260111070000_add_handoff_webhook_config_to_captain_assistants.rb`

- Adicionou coluna `handoff_webhook_config` (JSONB) na tabela `captain_assistants`
- Permite armazenar configuração do webhook:
  ```json
  {
    "enabled": true,
    "url": "https://...",
    "headers": { "Authorization": "Bearer ..." },
    "retry_attempts": 3,
    "timeout_seconds": 5
  }
  ```

#### 2. Backend Service ✅

**Arquivo:** `enterprise/app/services/captain/handoff_webhook_service.rb`

Funcionalidades implementadas:

- Validação de webhook habilitado
- Construção de payload completo
- Envio HTTP POST com timeout configurável
- Headers customizáveis para autenticação
- Logging estruturado de sucesso/falha
- Exception tracking integrado

**Payload enviado:**

```json
{
  "event": "conversation.handoff",
  "timestamp": "2026-01-11T...",
  "conversation": {
    "id": 123,
    "display_id": 45,
    "status": "open",
    "inbox_id": 1,
    "assignee_id": null,
    "team_id": null
  },
  "contact": {
    "id": 456,
    "name": "João Silva",
    "phone_number": "+5561999887766",
    "email": "joao@example.com",
    "additional_attributes": {...}
  },
  "handoff_context": {
    "trigger": "sentiment|error|ai_decision",
    "sentiment": "frustrated",
    "reason": "...",
    "last_message": "...",
    "conversation_summary": "..."
  },
  "assistant": {
    "id": 1,
    "name": "Hotel Assistant"
  }
}
```

#### 3. Integração com ResponseBuilderJob ✅

**Arquivo:** `enterprise/app/jobs/captain/conversation/response_builder_job.rb`

Mudanças aplicadas:

- Adicionado método `deliver_handoff_webhook` após `apply_handoff_side_effects`
- Método `determine_handoff_trigger` para identificar origem da escalação (sentimento, erro, ou decisão da IA)
- Método `build_conversation_summary` que prioriza insights do CRM ou concatena últimas 5 mensagens
- Integração automática no fluxo de handoff existente

#### 4. Frontend UI ✅

**Arquivo:** `app/javascript/dashboard/components-next/captain/pageComponents/assistant/settings/AssistantWebhookSettings.vue`

Componente Vue completo com:

- Toggle para habilitar/desabilitar webhook
- Input para URL do webhook (validação obrigatória)
- Lista dinâmica de headers customizados (usando `HeaderRow.vue` existente)
- Configuração de retry attempts (0-5)
- Configuração de timeout (1-30 segundos)
- Botão "Testar Webhook" (placeholder para futura implementação)
- Validação de formulário antes de submit

#### 5. Tradução (i18n) ✅

Adicionado keys em:

- `app/javascript/dashboard/i18n/locale/en/integrations.json`
- `app/javascript/dashboard/i18n/locale/pt_BR/integrations.json`

Keys criadas: `CAPTAIN.ASSISTANTS.WEBHOOK.*`

#### 6. Integração na Página de Configurações ✅

**Arquivo:** `app/javascript/dashboard/routes/dashboard/captain/assistants/settings/Settings.vue`

- Importado `AssistantWebhookSettings`
- Adicionado como nova seção entre "System Settings" e "Delete Assistant"
- Conectado ao handler `handleSubmit` existente para salvar configuração

### Arquivos Criados

1. `db/migrate/20260111070000_add_handoff_webhook_config_to_captain_assistants.rb`
2. `enterprise/app/services/captain/handoff_webhook_service.rb`
3. `app/javascript/dashboard/components-next/captain/pageComponents/assistant/settings/AssistantWebhookSettings.vue`
4. `progresso/2026-01-11_handoff_webhook_implementation.md` (este arquivo)

### Arquivos Modificados

1. `enterprise/app/jobs/captain/conversation/response_builder_job.rb`
2. `app/javascript/dashboard/i18n/locale/en/integrations.json`
3. `app/javascript/dashboard/i18n/locale/pt_BR/integrations.json`
4. `app/javascript/dashboard/routes/dashboard/captain/assistants/settings/Settings.vue`

### Como Usar (Para o Usuário)

1. **Ativar Migration:**

   ```bash
   bundle exec rails db:migrate
   ```

2. **Configurar Webhook:**

   - Acessar: Captain → Assistants → [Seu Assistant] → Settings
   - Scroll até seção "Webhook de Escalação"
   - Ativar toggle
   - Inserir URL (ex: `https://api.seucrm.com/handoff`)
   - (Opcional) Adicionar headers de autenticação:
     - Header: `Authorization`
     - Value: `Bearer SEU_TOKEN_AQUI`
   - Ajustar retry/timeout se necessário
   - Salvar

3. **Testar:**
   - Criar conversa no Captain que vai escalar (ex: perguntar algo que a IA não sabe)
   - Verificar logs do Rails para confirmar envio:
     ```
     [HandoffWebhook] Sending to https://... for conversation 123
     [HandoffWebhook] Success: 200 for conversation 123
     ```
   - Verificar recebimento no endpoint externo

### Segurança Implementada

- ✅ Headers customizáveis para autenticação
- ✅ Timeout configurável (evita bloqueio infinito)
- ✅ Exception tracking (Sentry/similar)
- ✅ Validação de URL presente antes de enviar
- ✅ Logs estruturados com conversation_id para auditoria

### Pendências (Futuras PRs)

- [ ] Endpoint de teste de webhook (botão "Testar Webhook" atualmente só loga no console)
- [ ] Retry automático com Sidekiq (`Captain::HandoffWebhookRetryJob`)
- [ ] Dashboard de monitoramento de webhooks (taxa de sucesso, latência)
- [ ] Validação de URL (força HTTPS em produção)
- [ ] Rate limiting (máx 100 webhooks/min)

### Próxima Fase

Fase 2: Sistema de Notificações Internas Aprimoradas (ActionCable, Toasts, Badges, Sons)

---

**Status:** ✅ **FASE 1 COMPLETA**
