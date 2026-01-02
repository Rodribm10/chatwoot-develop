# WuzAPI Reliability & Sync Plan (Phase 9)

## Goal

Fix outbound message failures (remove 24h restriction) and enable 2-way sync so messages sent from the mobile device appear in Chatwoot.

## Issues to Fix

1.  **Outbound Failure ("Falha ao enviar"):**

    - **Cause A (Likely):** Chatwoot UI prevents sending due to "24h Window" restriction (Red banner in screenshot).
    - **Cause B:** `WuzapiService` failing with API error (Auth/URL).
    - **Cause C:** Phone number formatting mismatch.

2.  **Mobile Sync (Missing Replies):**
    - **Cause:** We strictly ignore `from_me` messages in `IncomingMessageWuzapiService`.
    - **Requirement:** We must process `from_me` messages as `message_type: :outgoing` to reflect phone-initiated replies.

## Implementation Steps

### 1. Disable 24h Window for WuzAPI

The 24h window is a WhatsApp Business Policy constraint. For WuzAPI (User App API), this restriction does not exist technically. We must tell Chatwoot to ignore it.

- **Action:** Override `messaging_window_enabled?` in `Channel::Whatsapp`.
- **Logic:** Return `false` if `provider == 'wuzapi'`.

### 2. Debug & Fix Outbound Service

- **Action:** Verify `WuzapiService#send_message` actually works.
- **Action:** Enhance `send_message` to capture the WuzAPI `id` from the response (if available) and update the `Message` record `source_id`. This is critical for deduplication.

### 3. Implement Mobile Sync (Two-Way)

- **File:** `app/services/whatsapp/incoming_message_wuzapi_service.rb`
- **Logic Change:**
  - **Remove:** `return if parser.from_me?` loop protection (the "dumb" one).
  - **Add:** "Smart" Echo Handling.
    - If `parser.from_me?`, set `message_type = :outgoing`.
    - **Crucial:** Rely on `Strong Dedupe` (checking `source_id`).
    - _Scenario:_ Chatwoot creates message -> Sends to WuzAPI -> WuzAPI returns ID key -> Chatwoot updates `source_id`. -> Webhook arrives with same `ID` -> **Ignored** (Correct).
    - _Scenario:_ Phone sends message -> Webhook arrives with `ID` -> Chatwoot doesn't have it -> **Created** as `outgoing` (Correct).

## Verification Plan

1.  **Console Test:** Send message via `Rails c` logic to confirm API works.
2.  **UI Test:** Refresh page, check if Red Banner is gone. Try sending.
3.  **Sync Test:** Send "Teste do Celular" from WhatsApp mobile. Check if it appears in Chatwoot as an agent message.
