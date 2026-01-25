# WuzAPI Reply/Quote System - Technical Documentation

> **Last Updated:** 2026-01-24
> **Status:** ✅ Working
> **Author:** AI Assistant

## Overview

This document explains how the Reply/Quote feature works for WhatsApp messages through WuzAPI integration. When a user replies to a message in WhatsApp, the quoted message should appear in Chatwoot's interface.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              REPLY FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────┘

WhatsApp User replies to a message
          │
          ▼
┌────────────────────┐
│   WuzAPI Server    │ ──► Sends webhook with contextInfo.stanzaID
└────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Chatwoot Backend                                        │
│                                                                              │
│  1. WhatsappController.sanitize_payload_for_sidekiq (preserves stanzaID)    │
│  2. WhatsappEventsJob → IncomingMessageWuzapiService                        │
│  3. PayloadParser.in_reply_to_external_id (extracts stanzaID)               │
│  4. build_message → finds original by source_id, sets in_reply_to_id        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Chatwoot Frontend                                       │
│                                                                              │
│  MessageList.vue → getInReplyToMessage() → looks up inReplyToId             │
│  Base.vue → displays replyToPreview                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Files

| File                                                                | Purpose                                  |
| ------------------------------------------------------------------- | ---------------------------------------- |
| `app/controllers/webhooks/whatsapp_controller.rb`                   | Sanitizes payload, preserves `stanzaID`  |
| `app/services/whatsapp/incoming_message_wuzapi_service.rb`          | Creates message with `in_reply_to_id`    |
| `app/services/whatsapp/providers/wuzapi/payload_parser.rb`          | Extracts `stanzaID` from contextInfo     |
| `app/services/whatsapp/providers/wuzapi_service.rb`                 | Sends messages, returns clean `WAID:xxx` |
| `app/javascript/dashboard/components-next/message/MessageList.vue`  | Resolves reply reference                 |
| `app/javascript/dashboard/components-next/message/bubbles/Base.vue` | Displays quoted message                  |

---

## How It Works

### 1. Incoming Reply (WhatsApp → Chatwoot)

**Step 1: WuzAPI sends webhook with reply context**

```json
{
  "event": {
    "Message": {
      "extendedTextMessage": {
        "text": "My reply message",
        "contextInfo": {
          "stanzaID": "3EB0B12FB7571691E025DD",
          "participant": "556191544165@s.whatsapp.net",
          "quotedMessage": { "conversation": "Original message" }
        }
      }
    }
  }
}
```

**Step 2: Sanitizer preserves stanzaID** (`whatsapp_controller.rb` lines 84-90)

```ruby
if msg['extendedTextMessage']['contextInfo'].is_a?(Hash)
  ctx = msg['extendedTextMessage']['contextInfo']
  clean_msg['extendedTextMessage']['contextInfo'] = {
    'stanzaID' => ctx['stanzaID'] || ctx['stanzaId'],
    'participant' => ctx['participant']
  }.compact
end
```

**Step 3: PayloadParser extracts stanzaID** (`payload_parser.rb`)

```ruby
def in_reply_to_external_id
  msg = unwrap_ephemeral_message(params.dig(:event, :Message))
  ctx = msg.dig(:extendedTextMessage, :contextInfo)
  return ctx[:stanzaID] || ctx[:stanzaId] if ctx.present?
  # ... also checks imageMessage, videoMessage, etc.
end
```

**Step 4: IncomingMessageWuzapiService links messages** (lines 112-124)

```ruby
if (reply_id = parser.in_reply_to_external_id).present?
  clean_reply_id = "WAID:#{reply_id}"
  original_message = conversation.messages.find_by(source_id: clean_reply_id)

  if original_message
    msg_params[:in_reply_to_id] = original_message.id
  else
    # Fallback: store for UI display
    msg_params[:content_attributes] = { in_reply_to_external_id: clean_reply_id }
  end
end
```

### 2. Outgoing Messages (Chatwoot → WhatsApp)

**CRITICAL**: The `source_id` must be saved in format `WAID:xxx` for replies to work!

**WuzapiService.send_message** extracts ID from response:

```ruby
def send_message(phone_number, message)
  # ... send message to WuzAPI ...
  response = client.send_text(...)
  extract_message_id(response)  # Returns "WAID:xxx"
end

def extract_message_id(response)
  # WuzAPI returns: {"code" => 200, "data" => {"Id" => "xxx"}}
  message_id = response.dig('data', 'Id')
  return nil if message_id.blank?
  "WAID:#{message_id}"
end
```

### 3. Frontend Display

**MessageList.vue** resolves the reply:

```javascript
const getInReplyToMessage = parentMessage => {
  const inReplyToMessageId =
    parentMessage.inReplyToId ?? parentMessage.contentAttributes?.inReplyTo;

  if (!inReplyToMessageId) return null;
  return props.messages?.find(msg => msg.id === inReplyToMessageId);
};
```

**Base.vue** displays the preview:

```vue
<div v-if="inReplyTo" class="p-2 -mx-1 mb-2 rounded-lg cursor-pointer">
  <span class="break-all line-clamp-2">{{ replyToPreview }}</span>
</div>
```

---

## Troubleshooting Guide

### ❌ Reply not showing in Chatwoot

**Check 1: Is stanzaID in the webhook?**

```bash
grep "WuzAPI Reply Debug" log/development.log | tail -10
```

- ✅ Good: `Found extendedTextMessage contextInfo = {"stanzaID" => "xxx"}`
- ❌ Bad: `Message keys = []` or `No reply context found`

If stanzaID is missing, the message was NOT sent as a reply in WhatsApp.

**Check 2: Is source_id in correct format?**

```bash
bundle exec rails runner "puts Message.last(5).pluck(:id, :source_id, :in_reply_to_id)"
```

- ✅ Good: `source_id: "WAID:3EB0B12FB7571691E025DD"`
- ❌ Bad: `source_id: "{\"code\" => 200, ...}"` (JSON instead of ID)

If format is wrong, check `WuzapiService.extract_message_id`.

**Check 3: Can original message be found?**
The reply searches for: `WAID:#{stanzaID}`
The original must have `source_id` = `WAID:#{same_id}`

If IDs don't match, the original wasn't saved correctly.

---

## Common Issues & Fixes

| Problem                       | Cause                                       | Solution                                   |
| ----------------------------- | ------------------------------------------- | ------------------------------------------ |
| `source_id` is JSON           | `extract_message_id` not returning clean ID | Check `wuzapi_service.rb` line ~155        |
| stanzaID not in payload       | Sanitizer removing it                       | Check `whatsapp_controller.rb` lines 84-90 |
| Reply detected but not linked | Original message not found                  | Check if original has matching `source_id` |
| Frontend not showing          | `inReplyToId` null in API response          | Check jbuilder includes `in_reply_to_id`   |

---

## Testing Checklist

1. **Send message from Chatwoot**

   - Check: `source_id` saved as `WAID:xxx` format

2. **Reply to that message in WhatsApp**

   - Check: Webhook has `contextInfo.stanzaID`
   - Check: `in_reply_to_id` is set in new message

3. **View in Chatwoot UI**
   - Check: Quote box appears above message

---

## Debug Commands

```bash
# See recent messages with reply info
bundle exec rails runner "
Message.last(10).each do |m|
  puts \"#{m.id}: #{m.content&.truncate(30)} | source_id: #{m.source_id} | in_reply_to_id: #{m.in_reply_to_id}\"
end
"

# Check webhook payload for stanzaID
grep "stanzaID" log/development.log | tail -5

# See reply debug logs
grep "WuzAPI Reply Debug" log/development.log | tail -20
```

---

## Files Changed in This Implementation

1. **`app/services/whatsapp/providers/wuzapi_service.rb`**

   - Added `extract_message_id(response)` method
   - Returns `WAID:xxx` format instead of raw JSON

2. **`app/services/whatsapp/providers/wuzapi/payload_parser.rb`**

   - Enhanced `in_reply_to_external_id` with debug logging
   - Handles multiple message types (text, image, video, etc.)

3. **`app/services/whatsapp/incoming_message_wuzapi_service.rb`**

   - `build_message` method links replies via `in_reply_to_id`
   - Fallback stores `in_reply_to_external_id` in content_attributes

4. **`app/controllers/webhooks/whatsapp_controller.rb`**
   - Sanitizer preserves `stanzaID` and `participant` in contextInfo
