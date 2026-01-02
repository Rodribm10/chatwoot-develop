# Jasmine BrainService Implementation

## Phase 1: Foundation

- [x] Migration: Add new fields to jasmine_inbox_configs
- [ ] Add ENV fallback for DEFAULT_JASMINE_DISTANCE_THRESHOLD
- [ ] Seed: Create intent_keywords for hotel/motel business

## Phase 2: BrainService Core

- [x] Create Jasmine::BrainService skeleton
- [x] Create IntentDetector component
- [x] Create StrategyDecider component
- [x] Create PromptAssembler component
- [x] Create StateUpdater component

## Phase 3: Integration

- [x] Hook BrainService to incoming messages
- [x] Add logging for decisions (intent, strategy, RAG usage)

## Phase 4: Testing

- [ ] Specs for IntentDetector
- [ ] Specs for StrategyDecider (RAG mandatory vs prohibited)
- [ ] Specs for threshold handling
- [ ] Specs for loop protection (rag_queries > 5)

## Phase 5: UI

- [/] Add System Prompt field to config UI (Done)
- [/] Add Playbook field to config UI (Done)
- [/] Add threshold/model settings to config UI (Done)

## Phase 6: Jasmine Tools (New)

- [x] Backend: Create jasmine_tool_configs table and model
- [x] Backend: Create ToolRunner service
- [x] Backend: Create ToolsController
- [x] Frontend: Add Tools API client
- [x] Frontend: Add JasmineToolCard component
- [x] Frontend: Add JasmineToolsTab component
- [x] Frontend: Integrate with InboxDashboard
- [x] UI Refinement: Improve scrolling and layout
- [ ] Tests: Add RSpec tests

## Phase 7: Jasmine + Captain Unification (V1)

- [x] **Correção da Instabilidade no Ambiente Local**
  - [x] Identificar causa dos erros 500 intermitentes (Conflito de Porta DB 5432 vs 5438)
  - [x] Resolver problema de versão do Ruby/Bundler (`rbenv init`)
  - [x] corrigir formato do telefone no webhook (`Inactive Channel` - falta do DDI 55)
  - [x] Criar documentação de solução de problemas (`solucao_ambiente_wuzapi.md`)
- [ ] **Phase 1: Architecture Mapping**

  - [ ] Map Message Entry Point
  - [ ] Map Knowledge Base Decision Logic
  - [ ] Map Prompt Assembly
  - [ ] Map Tool Execution
  - [ ] Deliver: Mapping Report & Injection Point Identification

- [ ] **Phase 2: Brain Layer Implementation**

  - [x] Schema: Create `captain_tool_configs` table
  - [x] Schema: Update `captain_assistants` for Multi-LLM (`llm_provider`, `llm_model`)
  - [x] Backend: `AssistantChatService` Dynamic Provider Logic
  - [x] File: `enterprise/app/services/captain/llm/jasmine_brain.rb` (Skeleton)
  - [x] Refactor: `JasmineBrain` with Real LLM Logic (Thinking Step)
  - [x] File: `enterprise/app/services/captain/tools/definitions.rb`
  - [x] File: `enterprise/app/services/captain/tools/tool_runner.rb`
  - [x] File: `enterprise/app/services/captain/tools/parsers/status_suites_parser.rb`
  - [x] Inject: `AssistantChatService#generate_response`

- [x] **Phase 3: Tools Integration (UI)**

  - [x] Backend: Create `Captain::ToolsController` (or extend existing) to manage `captain_tool_configs`
  - [x] Frontend: Create "Ferramentas" tab inside Captain Assistant settings
  - [x] Frontend: Build form for Tool Key, Enabled, PlugPlay ID/Token, Webhook URL

- [x] **Phase 4: Output Normalization**

  - [x] Ensure normalized JSON output from tools

- [x] **Phase 5: Webhook Tools & Handoff**

  - [x] Implement Webhook Tools
  - [x] Implement Human Handoff (`escalar_humano`)

- [x] **Phase 6: Final Integration**
  - [x] Inject Brain Layer into Captain Pipeline
  - [x] Final Verification

## Phase 8: Native WuzAPI Channel (V1 Standard)

- [x] **Security (Foundation)**

  - [x] DB: Migration for `encrypted_wuzapi_user_token` & `admin_token`
  - [x] Model: Add `encrypts` to `Channel::Whatsapp`
  - [x] Code: Migrate checks from `provider_config` to encrypted cols
  - [x] Fix: Rename columns to match Rail convention (`wuzapi_user_token`)

- [x] **Inbound (V1 Contract)**

  - [x] Parser: Create `Wuzapi::PayloadParser` (Strict Contract)
  - [x] Service: Implement Strong Dedupe (Source ID Check)
  - [x] Service: Implement Loop Protection (`is_from_me`)
  - [x] Fix: Tunnel Connectivity & Webhook Config

- [x] **Outbound (V1)**

  - [x] Service: Switch to encrypted token usage
  - [x] Service: Ensure Text Sending works
  - [x] Service: Fix 401 Auth (Header/Token Logic)

- [x] **Sync (V1.5)**
  - [x] Implement Mobile Sync (Two-Way)
  - [x] Handle `from_me` messages as Outgoing
- [x] **Fix: Instability**
  - [x] Update Webhook URL (New Tunnel)
  - [x] Verify `from_me` sync reliability

## Phase 9: Automation & Cleanup (VPS Ready)

- [x] **Automation**

  - [x] Job: Create `Wuzapi::ConfigureWebhookJob` (Implemented as Model Callback)
  - [x] Hook: Trigger on `Channel::Whatsapp` create/update
  - [x] Logic: Set Webhook to `#{FRONTEND_URL}/webhooks/whatsapp/#{phone}`
  - [x] Logic: Set `Events: ['All']`

- [x] **Documentation**
  - [x] Update `wuzapi_walkthrough.md` with final architecture.
