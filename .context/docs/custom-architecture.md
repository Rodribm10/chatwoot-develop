# Custom Architecture: WuzAPI, Jasmine & Captain V2

This document outlines the **specific customizations** applied to this Chatwoot instance. It supersedes generic documentation for the modules listed below.

## 1. WuzAPI Integration Module (V1.5)

We do not use the standard WhatsApp Cloud API. We use a custom integration with **WuzAPI** (a Go-based WhatsApp gateway).

### 1.1 V1 Contract (Critical)

- **Token Storage:** TOKENS ARE NEVER PLAIN TEXT. They are stored in `encrypted_wuzapi_user_token` and `encrypted_wuzapi_admin_token` in the `channel_whatsapp` table.
- **Deduplication:** We use a `Redis` lock + `Source ID` check to prevent processing the same message twice (WuzAPI often sends retries).
- **Loop Protection:** Messages with `key.fromMe = true` are **OUTGOING** messages synced from the phone. They must be created as `message_type: :outgoing` and MUST NOT trigger bots.

### 1.2 Webhook Flow

1. **Ingress:** `POST /webhooks/whatsapp/:phone_number`
2. **Controller:** `Webhooks::WhatsappController` delegates to `WhatsappEventsJob`.
3. **Job:** Detects `wuzapi` provider -> delegates to `IncomingMessageWuzapiService`.
4. **Service:**
   - Finds/Creates Contact (checking variations of DDI 55).
   - Creates Message.
   - **Sync Logic:** If `IsFromMe: true` -> Create Outgoing Message.

---

## 2. Jasmine Brain (The Intelligence Layer)

Jasmine is a specialized logical layer responsible for **Intent Detection**, **Strategy Decision**, and **Sales Development (SDR)** behavior.

### 2.1 Core Components

- **BrainService:** The entry point. Receives a conversation context and decides "What to do".
- **IntentDetector:** Analyzes user input (using Gemini/OpenAI) to classify intent (e.g., `sales_inquiry`, `support_ticket`, `spam`).
- **StrategyDecider:** Based on intent, decides the workflow (e.g., "Handover to human", "Consult Knowledge Base", "Qualify Lead").
- **Playbooks:** Structured scripts for SDR qualification (Ask Name -> Ask Budget -> Schedule Demo).

---

## 3. Captain V2 (The Unification)

We are unifying Jasmine (Brain) into Captain (Body).

### 3.1 Architecture Shift

- **Legacy Captain:** Used OpenAI hardcoded logic to summarize/reply.
- **Captain V2:** A flexible Agent Runner that executes the **Jasmine Brain**.

### 3.2 Key Classes

- **`AgentRunnerService`:** The orchestrator. It manages the conversation loop, tool execution, and thinking process.
- **`ProviderFactory`:** A factory that returns the configured LLM client (Gemini, OpenRouter, OpenAI) based on the Inbox settings.
- **`JasmineBrain`:** A specialized Agent/Tool injected into the runner to perform high-level reasoning.

### 3.3 Configuration (Multi-LLM)

Configurations are stored in `captain_inbox_configs` (or `chat_assistants`):

- `llm_provider`: `gemini` | `openai` | `openrouter`
- `llm_model`: `gemini-1.5-flash` | `gpt-4o`
- `api_key`: Encrypted credential for the specific inbox (optional, falls back to ENV).

---

## 4. Troubleshooting & Operational Rules

### 4.1 Database Connectivity

- Development uses Docker Postgres on **Port 5438**.
- `export POSTGRES_PORT=5438` is REQUIRED before `rails c` or `foreman start`.

### 4.2 Ruby Environment

- Project uses **Ruby 3.4.4**.
- Always run `eval "$(rbenv init -)"` if `bundle` fails.

### 4.3 Webhooks

- WuzAPI URL must include the FULL phone number with DDI (e.g., `5561...`).
- Database `phone_number` must match exactly.
