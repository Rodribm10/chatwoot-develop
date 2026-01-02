# WuzAPI Native Channel Implementation Plan (V2 - Strict V1 Specs)

## Goal

Implement WuzAPI as a native `Channel::Whatsapp` provider, adhering to strict V1 requirements: text-only, strong deduplication, and encrypted token storage.

## User Review Required

> [!IMPORTANT] > **Schema Change**: Adding `encrypted_wuzapi_user_token` and `encrypted_wuzapi_admin_token` (plus IVs) to `channel_whatsapp` to replace insecure JSONB storage.

> [!WARNING] > **V1 Scope**: Only `text` messages supported. Groups and self-messages are explicitly ignored.

## Proposed Changes

### Database

#### [NEW] Migration: Add Encrypted Tokens to Channel Whatsapp

- Add `encrypted_wuzapi_user_token` (string)
- Add `encrypted_wuzapi_user_token_iv` (string)
- Add `encrypted_wuzapi_admin_token` (string)
- Add `encrypted_wuzapi_admin_token_iv` (string)
- _Rationale_: Avoids storing sensitive tokens in `provider_config` (JSONB).

### Backend (Models)

#### [MODIFY] `app/models/channel/whatsapp.rb`

- Add `encrypts :wuzapi_user_token, :wuzapi_admin_token` (Rails 7+ encryption).
- Update `validate_provider_config` to check these new fields instead of JSONB.

### Backend (Services)

#### [NEW] `app/services/whatsapp/providers/wuzapi/payload_parser.rb`

- Implement class to strictly parse WuzAPI payload per contract:
  - `external_id` <- `body.event.Info.ID`
  - `from_me` <- `body.event.Info.IsFromMe`
  - `wa_id` <- `body.event.Info.Sender` (parsed)
  - `text` <- `body.event.Message.conversation`
  - `timestamp` <- `body.event.Info.Timestamp`

#### [MODIFY] `app/services/whatsapp/incoming_message_wuzapi_service.rb`

- Integrate `PayloadParser`.
- Implement **Strong Dedupe**:
  - Return early if `Message.exists?(source_id: external_id, inbox_id: inbox.id)`.
- Implement Loop Protection:
  - Return early if `from_me` is true.

#### [MODIFY] `app/services/whatsapp/providers/wuzapi_service.rb` (Outbound)

- Update to use `channel.wuzapi_user_token` (decrypted) instead of `provider_config`.
- Ensure `send_message` handles errors gracefully.

### Security

- **Token Migration**: If any data exists (unlikely in prod yet), migrate from `provider_config` to encrypted columns.

## Verification Plan

### Automated Tests

- **Request Spec (`spec/requests/webhooks/whatsapp_controller_spec.rb`)**
  - Verify WuzAPI payload submission creates a message.
  - Verify duplicate payload does NOT create a second message (Idempotency).
  - Verify `is_from_me: true` is ignored.

### Manual Verification

1. **Setup**: Create Inbox with WuzAPI, providing Token.
2. **Persistence**: Verify Token is stored in encrypted columns (checked via Rails Console).
3. **Inbound**: Send "Hello" from WhatsApp. Verify it appears in Chatwoot.
4. **Dedupe**: Replay the same webhook JSON. Verify no new message.
5. **Outbound**: Reply "World" from Chatwoot. Verify delivery to WhatsApp.
