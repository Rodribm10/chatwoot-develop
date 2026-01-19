# Runbook: Reserva Conversacional com Pix (Jasmine -> Daniela)

**Data:** 16/01/2026
**Objetivo:** garantir que a conversa gere reserva e envie Pix Copia e Cola via sub-agente Daniela.

## 1. Fluxo esperado (resumo)

1) Jasmine identifica reserva futura e chama o sub-agente `daniela_reservas`.
2) Daniela usa ferramentas internas para:
   - atualizar contato (nome/CPF),
   - consultar disponibilidade e preco,
   - criar rascunho de reserva,
   - gerar Pix.
3) Pix Copia e Cola e enviado como mensagem separada no WhatsApp.

## 2. Configuracoes que precisam estar ativas

### 2.1 Assistente Jasmine

- **Cenario habilitado:** `Daniela Reservas` (tool key `consultar_daniela_reservas`).
- **Ferramentas disponiveis no cenario:**
  - `update_contact`
  - `check_availability`
  - `create_reservation_intent`
  - `generate_pix`
- **Modelo/Chave LLM:** `assistant.api_key` valido (ou `CAPTAIN_OPEN_AI_API_KEY`).

### 2.2 Pipeline de decisao (JasmineBrain)

- A decisao precisa carregar `tool_input` quando `strategy = execute_tool`.
- A chamada do runner precisa incluir `additional_data: { message:, tool_input: }`.

Arquivos envolvidos:
- `enterprise/app/services/captain/llm/jasmine_brain.rb`
- `enterprise/app/services/captain/llm/assistant_chat_service.rb`
- `enterprise/app/services/captain/tools/tool_runner.rb`

### 2.3 Sub-agente Daniela (ScenarioDelegatorTool)

- O runner deve ser chamado com `runner.run(pergunta_interna, max_turns: ...)`.
- Se o sub-agente falhar, existe fallback para concluir a reserva e gerar Pix.

Arquivo:
- `enterprise/lib/captain/tools/scenario_delegator_tool.rb`

### 2.4 Pix (Banco Inter)

- `Captain::Inter::CobService` exige no `unit`:
  - `inter_pix_key`
  - `inter_account_number`
  - `inter_cert_path`
  - `inter_key_path`

Arquivo:
- `enterprise/app/services/captain/inter/cob_service.rb`

### 2.5 Unidade vinculada ao Inbox

- O Inbox da conversa deve estar ligado a uma unidade:
  - `conversation.inbox.captain_inbox.unit`.

### 2.6 Precos e sinal (Pix 50%)

- **Preco enviado ao cliente** vem de `Captain::Pricing`:
  - UI: `/accounts/:accountId/captain/pricings` (Dashboard > Captain > Pricings).
  - API: `GET /api/v1/accounts/:account_id/captain/pricings`.
- **Pix Copia e Cola** cobra 50% do `total_amount`:
  - `enterprise/app/services/captain/inter/cob_service.rb` (WhatsApp/Conversas).
  - `app/services/captain/inter_service.rb` (API publica).

## 3. Fluxo tecnico detalhado (estado)

1) **Atualiza contato**
   - `update_contact` grava nome/CPF no contato.
2) **Criar rascunho**
   - `create_reservation_intent(suite, price)` cria reserva `draft`.
3) **Gerar Pix**
   - `generate_pix` busca o ultimo `draft` e gera Pix.
   - Atualiza reserva para `pending_payment`.
   - Envia Pix Copia e Cola como mensagem unica (somente o codigo).
   - Se ja existir Pix em `pending_payment`, reenvia se ainda valido; se expirado (1h), gera um novo.

Arquivos:
- `enterprise/app/services/captain/tools/update_contact_tool.rb`
- `enterprise/app/services/captain/tools/create_reservation_intent_tool.rb`
- `enterprise/app/services/captain/tools/generate_pix_tool.rb`

## 4. Fallback automatico (quando o sub-agente falha)

Se o sub-agente `Daniela Reservas` retorna erro, o fallback executa:

- Extrair nome/CPF do texto recebido.
- Atualizar contato com nome/CPF.
- Reutilizar `pending_payment` se ja existir Pix (reenviar mensagem).
- Se nao houver rascunho, criar `draft` via `create_reservation_intent`.
- Gerar Pix via `generate_pix`.

Arquivo:
- `enterprise/lib/captain/tools/scenario_delegator_tool.rb`

## 5. Checklist rapido para restaurar se quebrar

1) **Cenario Daniela habilitado** no assistente Jasmine.
2) **Ferramentas listadas** no cenario: `update_contact`, `check_availability`, `create_reservation_intent`, `generate_pix`.
3) **JasmineBrain** retorna `tool_input` (nao pode ser perdido).
4) **ToolRunner** passa `tool_input` para ferramentas e seta `pergunta_interna`.
5) **ScenarioDelegatorTool** chama runner corretamente e fallback ativo.
6) **Unit do inbox** com dados do Inter (pix key, conta, certificados).

## 6. Logs de referencia (sinais de sucesso)

- `CreateReservationIntentTool`:
  - `SUCCESS: Reserva iniciada com sucesso!`
- `GeneratePixTool`:
  - `Cobrança Pix gerada com sucesso. Copia e Cola enviado...`
- Mensagem enviada no WhatsApp com:
  - apenas o codigo Pix (uma mensagem dedicada)

Logs uteis:
- `log/tool_debug.log`
- `log/development.log`
- `log/brain_debug.log`

## 7. Alertas comuns

- `undefined method 'type' for an instance of String` dentro do sub-agente.
  - O fallback cobre isso, mas se quebrar verifique o runner.
- `Text and attachments cannot be both nil`.
  - Evitar mensagens vazias no contexto.
- `Incorrect API key`.
  - Ajustar `assistant.api_key` ou `CAPTAIN_OPEN_AI_API_KEY`.
