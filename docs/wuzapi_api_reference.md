---
title: Wuzapi API Reference
source: https://meow1001.innova1001.com.br/api/spec.yml
captured_at: 2026-01-19
draft: false
---

# WUZAPI API Reference

> **Note**: This documentation is derived from the official [spec.yml](https://meow1001.innova1001.com.br/api/spec.yml) (OpenAPI 3.0.0).

## Authentication

- **Standard Endpoints**: Include the `token` header with a valid user token (matches tokens stored in the `users` database table).
- **Admin Endpoints**: Use the `Authorization` header with the admin token (set in `.env` as `WUZAPI_ADMIN_TOKEN`).

---

## 🚀 Messages

### Send Text Message

`POST /chat/send/text`

Sends a text message. `ContextInfo` is optional and used when replying to a message.

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "Body": "Hello, how are you?",
  "Id": "optional-custom-id",
  "ContextInfo": {
    "StanzaId": "message-id-to-reply-to",
    "Participant": "5511999999999@s.whatsapp.net"
  }
}
```

### Send Image

`POST /chat/send/image`

Sends an image message. Image must be Base64 encoded (JPEG/PNG).

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "Image": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
  "Caption": "Check this out!",
  "Id": "optional-custom-id"
}
```

### Send Audio

`POST /chat/send/audio`

Sends an audio message (PTT/Voice Note). Audio must be Base64 encoded OGG/Opus.

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "Audio": "data:audio/ogg;base64,T2dnUw...",
  "Id": "optional-custom-id"
}
```

### Send Video

`POST /chat/send/video`

Sends a video message. Video must be Base64 encoded MP4.

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "Video": "data:video/mp4;base64,AAAA...",
  "Caption": "My video",
  "Id": "optional-custom-id"
}
```

### Send Document

`POST /chat/send/document`

Sends a generic document/file.

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "Document": "data:application/pdf;base64,JVBER...",
  "FileName": "invoice.pdf",
  "Id": "optional-custom-id"
}
```

---

## 💬 Chat Actions

### Set Chat Presence

`POST /chat/presence`

Sets the typing or recording status (e.g., "typing...", "recording audio...").

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "State": "composing",
  "Media": "audio"
}
```

- `State`: `composing` (typing) or `paused`.
- `Media`: `audio` (optional, indicates "recording audio").

### React to Message

`POST /chat/react`

Reacts to a specific message with an emoji.

**Request Body:**

```json
{
  "Phone": "5511999999999",
  "Body": "❤️",
  "Id": "message-id-to-react-to"
}
```

- To react to your _own_ message, prefix the `Id` with `me:` (e.g., `me:ABC12345`).

### Mark as Read

`POST /chat/markread`

Marks messages as read.

**Request Body:**

```json
{
  "Id": ["msg-id-1", "msg-id-2"],
  "Chat": "5511999999999@s.whatsapp.net"
}
```

---

## 👥 Groups

### Create Group

`POST /group/create`

Creates a new WhatsApp group.

**Request Body:**

```json
{
  "Name": "My New Group",
  "Participants": ["5511999999999", "5511888888888"]
}
```

### Get Group List

`GET /group/list`

Returns a list of all groups the connected number is a member of.

### Get Group Info

`GET /group/info?GroupJID=123456789@g.us`

Returns metadata and participants for a specific group.

### Update Participants

`POST /group/updateparticipants`

Add, remove, promote, or demote participants.

**Request Body:**

```json
{
  "GroupJID": "123456789@g.us",
  "Participants": ["5511999999999"],
  "Action": "add"
}
```

- `Action`: `add`, `remove`, `promote`, `demote`.

### Leave Group

`POST /group/leave`

**Request Body:**

```json
{
  "GroupJID": "123456789@g.us"
}
```

---

## 🔌 Session & Connection

### Connect / QR Code

`POST /session/connect`

Initiates the connection. If not connected, generates a QR code.

**Request Body:**

```json
{
  "Subscribe": ["Message", "ReadReceipt", "Presence"],
  "Immediate": false
}
```

### Get Session Status

`GET /session/status`

Returns connection health.

```json
{
  "data": {
    "Connected": true,
    "LoggedIn": true
  }
}
```

### Logout

`POST /session/logout`

Disconnects and clears the session files.

---

## 🎣 Webhooks

Configure where Wuzapi POSTs incoming events (messages, status updates).

### Set Webhook

`POST /webhook`

**Request Body:**

```json
{
  "webhook": "https://your-server.com/webhooks/wuzapi",
  "events": ["Message", "ReadReceipt", "Presence", "HistorySync"]
}
```

_(Common event types: `Message`, `ReadReceipt`, `Presence`, `ChatPresence`)_

### Get Webhook Config

`GET /webhook`

---

## 👤 User & Contacts

### Check Phones (Exist on WhatsApp?)

`POST /user/check`

**Request Body:**

```json
{
  "Phone": ["5511999999999", "5511888888888"]
}
```

### Get User Info

`POST /user/info`

Gets status message, profile picture ID, etc.

**Request Body:**

```json
{
  "Phone": ["5511999999999"]
}
```

### Get Contacts

`GET /user/contacts`

Returns a list of all saved contacts synced from the phone.
