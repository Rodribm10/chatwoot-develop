# Implementation Plan - Captain V2 Multi-LLM & Documentation

This plan addresses three key objectives:

1.  **Correcting the Context:** Updating `.context/docs` to reflect our specific WuzAPI/Jasmine/Captain architecture.
2.  **Multi-LLM Architecture:** Implementing a flexible LLM provider system (OpenAI/Gemini) for Captain.
3.  **Unification:** Integrating Jasmine's brain (Intent/SDR logic) into Captain's body (AgentRunner).

## User Review Required

> [!IMPORTANT] > **Database Schema Change**: We will add `llm_provider` and `llm_model` columns to `captain_inbox_configs`.
> **Configuration Strategy**: This allows _per-inbox_ configuration. One inbox can use GPT-4o (Sales), another Gemini 1.5 Flash (Support).

## Proposed Changes

### 1. Correcting the Context (Documentation)

We will create a specific architecture addendum file to avoid overwriting the generic generic Chatwoot docs every time.

#### [NEW] [.context/docs/custom-architecture.md](file:///Users/user/Chatwoot/chatwoot-develop/.context/docs/custom-architecture.md)

- **Content:**
  - **WuzAPI Integration Module:** Explains the V1 Contract (Encrypted Tokens, Webhook Handlers, Sync Logic).
  - **Jasmine Brain:** Explains Intent Detection, Strategy Decider, and Playbooks.
  - **Captain V2 (The Body):** Explains `AgentRunnerService` and how it delegates to the Brain.

### 2. Multi-LLM Backend Infrastructure

#### [MODIFY] [db/migrate/timestamp_add_llm_config_to_captain.rb](file:///Users/user/Chatwoot/chatwoot-develop/db/migrate/20260101000000_add_llm_config_to_captain.rb)

- Add columns to `captain_inbox_configs` (or `chat_assistants` table, checking existing schema first):
  - `llm_provider` (string, default: 'openai')
  - `llm_model` (string, default: 'gpt-3.5-turbo')
  - `api_key` (text, encrypted)

#### [MODIFY] [enterprise/app/services/captain/llm/provider_factory.rb](file:///Users/user/Chatwoot/chatwoot-develop/enterprise/app/services/captain/llm/provider_factory.rb)

- **New Service:** A factory pattern to instantiate the correct client.
- `def self.get_client(provider, config)`
  - Case `openai`: Returns `OpenAI::Client`
  - Case `gemini`: Returns `Gemini::QuickClient` (from our definition)

#### [MODIFY] [enterprise/app/services/captain/assistant/agent_runner_service.rb](file:///Users/user/Chatwoot/chatwoot-develop/enterprise/app/services/captain/assistant/agent_runner_service.rb)

- Update `generate_response` to use `ProviderFactory` instead of hardcoded OpenAI logic.

### 3. Jasmine Logic Injection

#### [MODIFY] [enterprise/app/services/captain/llm/jasmine_brain.rb](file:///Users/user/Chatwoot/chatwoot-develop/enterprise/app/services/captain/llm/jasmine_brain.rb)

- Ensure this class implements the "Thinking" step:
  1. Detect Intent (Sales/Support/Spam).
  2. Select Strategy.
  3. Assemble Prompt.

## Verification Plan

### Automated Tests

- **Migration:** Run `rails db:migrate` and verify schema.
- **Provider Factory:** Create a Rails Console script to request a completion from Gemini and OpenAI via the factory.

### Manual Verification

1.  **Configure:** Set Inbox 1 to use **Gemini 1.5 Flash**.
2.  **Chat:** Send a message "Quero comprar um carro".
3.  **Verify:**
    - Logs should show `[Captain] Using provider: gemini`
    - Response should come from Gemini.
    - Intent should be logged as `sales`.
