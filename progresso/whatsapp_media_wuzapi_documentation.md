# Documentação Técnica: WhatsApp Media (WuzAPI) no Chatwoot

> **Data de Criação:** 2026-01-24  
> **Última Atualização:** 2026-01-24  
> **Status:** ✅ FUNCIONANDO  
> **Autor:** Rodrigo + Antigravity AI

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Fluxo](#arquitetura-do-fluxo)
3. [Arquivos Críticos](#arquivos-críticos)
4. [Fluxo Detalhado](#fluxo-detalhado)
5. [Algoritmo de Decriptografia](#algoritmo-de-decriptografia)
6. [Sanitização do Payload](#sanitização-do-payload)
7. [Troubleshooting](#troubleshooting)
8. [Checklist de Restauração](#checklist-de-restauração)

---

## Visão Geral

### O Problema Original

O WhatsApp (via WuzAPI/whatsmeow) envia mídia **CRIPTOGRAFADA**. Diferente da Cloud API oficial da Meta que já entrega arquivos descriptografados, o WuzAPI entrega:

1. **URL criptografada** (`mmg.whatsapp.net/...`) - arquivo AES-256 criptografado
2. **mediaKey** - chave em base64 para derivar as chaves de decriptografia
3. **JPEGThumbnail** - preview em baixa resolução (binário, causa problemas de serialização)

### A Solução Implementada

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│  WhatsApp User  │───▶│  WuzAPI Server   │───▶│  Chatwoot Webhook   │
│  envia imagem   │    │  (whatsmeow)     │    │  (Controller)       │
└─────────────────┘    └──────────────────┘    └──────────┬──────────┘
                                                          │
                                          ┌───────────────▼───────────────┐
                                          │  1. SANITIZA PAYLOAD          │
                                          │  (Remove binários do JSON)    │
                                          └───────────────┬───────────────┘
                                                          │
                                          ┌───────────────▼───────────────┐
                                          │  2. SIDEKIQ JOB               │
                                          │  (WhatsappEventsJob)          │
                                          └───────────────┬───────────────┘
                                                          │
                                          ┌───────────────▼───────────────┐
                                          │  3. DECRIPTOGRAFIA            │
                                          │  WuzAPI endpoint OU local     │
                                          └───────────────┬───────────────┘
                                                          │
                                          ┌───────────────▼───────────────┐
                                          │  4. ACTIVE STORAGE            │
                                          │  (Salva arquivo descriptog.)  │
                                          └───────────────┬───────────────┘
                                                          │
                                          ┌───────────────▼───────────────┐
                                          │  5. FRONTEND                  │
                                          │  (Exibe thumbnail + full)     │
                                          └───────────────────────────────┘
```

---

## Arquivos Críticos

| Arquivo                                                    | Função                                                   |
| ---------------------------------------------------------- | -------------------------------------------------------- |
| `app/controllers/webhooks/whatsapp_controller.rb`          | Recebe webhook, SANITIZA payload, enfileira job          |
| `app/jobs/webhooks/whatsapp_events_job.rb`                 | Processa eventos, roteia para service correto            |
| `app/services/whatsapp/incoming_message_wuzapi_service.rb` | Cria mensagem, baixa/descriptografa mídia, anexa arquivo |
| `app/services/whatsapp/decryption_service.rb`              | Algoritmo de decriptografia WhatsApp (HKDF + AES)        |
| `app/services/whatsapp/providers/wuzapi/payload_parser.rb` | Extrai dados do payload WuzAPI                           |
| `lib/wuzapi/client.rb`                                     | Cliente HTTP para WuzAPI (`/chat/downloadimage`)         |

---

## Fluxo Detalhado

### FASE 1: Webhook Controller (Sanitização)

**Arquivo:** `app/controllers/webhooks/whatsapp_controller.rb`

```ruby
def process_payload
  # CRÍTICO: Remove RawMessage IMEDIATAMENTE
  # Isso DEVE ser a primeira coisa, antes de qualquer log
  params[:event]&.delete('RawMessage')
  params.dig(:event, 'Message')&.delete('RawMessage')

  # ... resto do código

  # WHITELIST sanitization antes de enfileirar
  sanitized_payload = sanitize_payload_for_sidekiq(params.to_unsafe_hash)
  Webhooks::WhatsappEventsJob.perform_later(sanitized_payload)
end

def sanitize_payload_for_sidekiq(raw_payload)
  # USA WHITELIST - só campos permitidos passam
  # NUNCA deixar passar: JPEGThumbnail, RawMessage, scansSidecar, etc.
end
```

> ⚠️ **CRÍTICO:** Se o `RawMessage` ou `JPEGThumbnail` chegarem ao Sidekiq, você verá o erro:
>
> ```
> JSON.generate: UTF-8 string passed as BINARY
> ```
>
> Isso acontece porque Sidekiq serializa argumentos em JSON, e dados binários não são UTF-8 válido.

### FASE 2: Sidekiq Job

**Arquivo:** `app/jobs/webhooks/whatsapp_events_job.rb`

```ruby
def perform(params)
  # Identifica canal e roteia para service correto
  if channel.provider == 'wuzapi'
    Whatsapp::IncomingMessageWuzapiService.new(...)
  else
    Whatsapp::IncomingMessageService.new(...)  # Cloud API
  end
end
```

### FASE 3: Service de Mensagem

**Arquivo:** `app/services/whatsapp/incoming_message_wuzapi_service.rb`

```ruby
def perform
  # 1. Parse do payload
  parser = Whatsapp::Providers::Wuzapi::PayloadParser.new(@params)

  # 2. Ignora tipos não-mensagem (ReadReceipt, etc)
  return if parser.message_type == :ignore

  # 3. Encontra/cria contato e conversa
  set_contact
  set_conversation

  # 4. Cria mensagem (sem salvar ainda)
  @message = build_message(parser)

  # 5. Anexa arquivos se houver
  attach_files(parser) if parser.attachment_params.present?

  # 6. Salva tudo
  @message.save!
end
```

### FASE 4: Download/Decriptografia

**Método:** `download_or_decrypt_media` em `incoming_message_wuzapi_service.rb`

```ruby
def download_or_decrypt_media(attachment_data, message_type)
  media_url = attachment_data[:external_url]

  # MÉTODO 1: WuzAPI endpoint (retorna mídia JÁ DESCRIPTOGRAFADA)
  begin
    wuzapi_response = wuzapi_client.download_media(wuzapi_token, media_url)
    if wuzapi_response['data'].present?
      decoded = Base64.decode64(wuzapi_response['data'])
      return StringIO.new(decoded) if decoded.bytesize > 1000
    end
  rescue => e
    Rails.logger.warn "WuzAPI endpoint failed: #{e.message}"
  end

  # MÉTODO 2: Decriptografia local
  if attachment_data[:media_key].present?
    decrypted = Whatsapp::DecryptionService.new(
      media_url,
      attachment_data[:media_key],
      message_type
    ).decrypt
    return decrypted if decrypted
  end

  # MÉTODO 3: Download direto (funciona para URLs não-criptografadas)
  Down.download(media_url, ...)
end
```

---

## Algoritmo de Decriptografia

**Arquivo:** `app/services/whatsapp/decryption_service.rb`

### Protocolo WhatsApp de Mídia

1. **Mídia é criptografada** com AES-256-CBC (sem padding)
2. **Chave derivada via HKDF** a partir do `mediaKey`
3. **Últimos 10 bytes** são MAC (removidos antes de decriptar)

### Info Strings (HKDF)

```ruby
INFO_STRINGS = {
  image: 'WhatsApp Image Keys',
  video: 'WhatsApp Video Keys',
  audio: 'WhatsApp Audio Keys',
  document: 'WhatsApp Document Keys',
  sticker: 'WhatsApp Image Keys'
}
```

### Derivação de Chaves

```ruby
# Input: mediaKey (32 bytes após decode base64)
# Output: 112 bytes expandidos

expanded_key = OpenSSL::KDF.hkdf(
  @media_key,
  salt: ''.b,        # Salt vazio (IMPORTANTE: binário, não string)
  info: @info,       # Ex: 'WhatsApp Image Keys'
  length: 112,
  hash: 'sha256'
)

# Divisão dos 112 bytes:
iv         = expanded_key[0...16]    # 16 bytes - Vetor de inicialização
cipher_key = expanded_key[16...48]   # 32 bytes - Chave AES-256
mac_key    = expanded_key[48...80]   # 32 bytes - Chave HMAC (opcional)
ref_key    = expanded_key[80...112]  # 32 bytes - Não usado
```

### Decriptografia

```ruby
# Remove últimos 10 bytes (MAC)
cipher_text = encrypted_bytes[0...-10]

# AES-256-CBC sem padding
decipher = OpenSSL::Cipher.new('AES-256-CBC')
decipher.decrypt
decipher.key = cipher_key
decipher.iv = iv
decipher.padding = 0  # CRÍTICO: WhatsApp não usa PKCS7

decrypted = decipher.update(cipher_text) + decipher.final
```

### Validação de Magic Bytes

Após decriptografia, valida que o arquivo é mídia válida:

```ruby
# JPEG:  FF D8 FF
# PNG:   89 50 4E 47
# WebP:  RIFF....WEBP
# MP4:   ....ftyp
# MP3:   ID3 ou FF FB
```

---

## Sanitização do Payload

### Campos que DEVEM ser removidos (NUNCA no JSON)

| Campo              | Localização                                    | Motivo          |
| ------------------ | ---------------------------------------------- | --------------- |
| `RawMessage`       | `event.RawMessage`, `event.Message.RawMessage` | Binário gigante |
| `JPEGThumbnail`    | `event.Message.imageMessage.JPEGThumbnail`     | Binário base64  |
| `scansSidecar`     | `event.Message.imageMessage.scansSidecar`      | Binário         |
| `firstScanSidecar` | `event.Message.imageMessage.firstScanSidecar`  | Binário         |
| `streamingSidecar` | `event.Message.videoMessage.streamingSidecar`  | Binário         |

### Abordagem WHITELIST (Recomendada)

```ruby
def sanitize_payload_for_sidekiq(raw_payload)
  # Constrói novo payload apenas com campos permitidos
  {
    'event' => {
      'Type' => raw_payload.dig('event', 'Type'),
      'Timestamp' => raw_payload.dig('event', 'Timestamp'),
      'Message' => sanitize_message(raw_payload.dig('event', 'Message')),
      # ... outros campos safe
    }
  }
end

def sanitize_message(msg)
  return nil if msg.blank?
  {
    'ID' => msg['ID'],
    'Timestamp' => msg['Timestamp'],
    'PushName' => msg['PushName'],
    # Para mídia, incluir APENAS metadados:
    'imageMessage' => sanitize_media_message(msg['imageMessage']),
    # NUNCA incluir: JPEGThumbnail, RawMessage, etc.
  }
end

def sanitize_media_message(media)
  return nil if media.blank?
  {
    'url' => media['url'],
    'directPath' => media['directPath'],
    'mediaKey' => media['mediaKey'],
    'mimetype' => media['mimetype'],
    'fileEncSha256' => media['fileEncSha256'],
    'fileSha256' => media['fileSha256'],
    'fileLength' => media['fileLength'],
    # BLOQUEADOS: JPEGThumbnail, scansSidecar, etc.
  }
end
```

---

## Troubleshooting

### Erro: `JSON.generate: UTF-8 string passed as BINARY`

**Causa:** Dados binários (JPEGThumbnail, RawMessage) chegando no Sidekiq.

**Solução:**

1. Verificar se `process_payload` remove `RawMessage` no início
2. Verificar se `sanitize_payload_for_sidekiq` usa WHITELIST
3. Verificar se não há `params.inspect` ou `.to_json` antes da sanitização

**Debug:**

```ruby
# No controller, ANTES de enfileirar:
Rails.logger.info "Payload keys: #{params[:event]&.keys}"
# Se aparecer 'RawMessage' ou 'JPEGThumbnail', a sanitização falhou
```

### Erro: `VipsForeignLoad: not a known file format`

**Causa:** Arquivo ainda está criptografado quando chega no ActiveStorage.

**Solução:**

1. Verificar se `mediaKey` está chegando no `attachment_params`
2. Verificar se `DecryptionService` está sendo chamado
3. Verificar se a decriptografia retorna dados válidos (magic bytes)

**Debug:**

```ruby
# Em download_or_decrypt_media:
Rails.logger.info "mediaKey present: #{attachment_data[:media_key].present?}"
Rails.logger.info "Decrypted size: #{decrypted&.size}"
```

### Erro: `WuzAPI endpoint failed - 502 Bad Gateway`

**Causa:** Servidor WuzAPI não conseguiu baixar mídia do WhatsApp.

**Solução:**

1. É esperado que falhe ocasionalmente - o fallback local funciona
2. Se falhar sempre, verificar conexão do WuzAPI com WhatsApp
3. A decriptografia local é o backup

### Imagem não aparece no frontend

**Verificar:**

1. Mensagem foi criada? (`Message.last`)
2. Attachment foi criado? (`Attachment.last`)
3. Blob existe? (`ActiveStorage::Blob.last`)
4. URLs estão populadas? (`Attachment.last.file_url`, `Attachment.last.thumb_url`)

```ruby
# Console debug:
a = Attachment.last
puts "Blob: #{a.file.blob.id}"
puts "Size: #{a.file.blob.byte_size}"
puts "Content-Type: #{a.file.blob.content_type}"
puts "URL: #{a.file_url}"
```

---

## Checklist de Restauração

Se o sistema quebrar, siga esta lista na ordem:

### 1. Verificar Controller (Sanitização)

```bash
# Abrir arquivo:
code app/controllers/webhooks/whatsapp_controller.rb

# Verificar:
# - Linha 1-10 de process_payload DEVE ter delete('RawMessage')
# - sanitize_payload_for_sidekiq DEVE existir e usar WHITELIST
# - perform_later DEVE receber sanitized_payload, NÃO params.to_unsafe_hash
```

### 2. Verificar Service (Download)

```bash
# Abrir arquivo:
code app/services/whatsapp/incoming_message_wuzapi_service.rb

# Verificar método download_or_decrypt_media:
# - Tenta WuzAPI endpoint primeiro
# - Fallback para DecryptionService
# - Fallback para download direto
```

### 3. Verificar DecryptionService

```bash
# Abrir arquivo:
code app/services/whatsapp/decryption_service.rb

# Verificar:
# - INFO_STRINGS corretos
# - HKDF com salt: ''.b (binário vazio)
# - AES-256-CBC com padding = 0
# - Remove últimos 10 bytes antes de decriptar
# - Validação de magic bytes
```

### 4. Verificar PayloadParser

```bash
# Abrir arquivo:
code app/services/whatsapp/providers/wuzapi/payload_parser.rb

# Verificar attachment_params inclui:
# - :external_url
# - :media_key
# - :mimetype
# - :file_name
```

### 5. Verificar Wuzapi Client

```bash
# Abrir arquivo:
code lib/wuzapi/client.rb

# Verificar método download_media:
# - POST /chat/downloadimage
# - Payload: { 'URL' => media_url }
```

### 6. Teste Manual

```bash
# Enviar imagem pelo WhatsApp e verificar logs:
tail -f log/sidekiq.log | grep -E "WuzAPI|Decrypt"

# Deve aparecer:
# - "WuzAPI: Processing attachment"
# - "WuzAPI: Attempting download via WuzAPI endpoint..."
# - OU "WuzAPI Decrypt: SUCCESS - Valid media detected"
# - "WuzAPI: Attachment queued for save"
# - "WuzAPI: Message created"
```

### 7. Verificar no Console

```ruby
# Rails console:
rails c

# Verificar última mensagem com imagem:
m = Message.where.not(attachments: { id: nil }).last
puts "Message ID: #{m.id}"
puts "Attachments: #{m.attachments.count}"

a = m.attachments.first
puts "Blob size: #{a.file.blob.byte_size}"
puts "Content-type: #{a.file.blob.content_type}"
puts "URL ok: #{a.file_url.present?}"
```

---

## Referências Técnicas

- **WhatsApp Media Encryption:** https://github.com/nicbarker/swift-whatsapp-media-decryptor
- **HKDF RFC 5869:** https://tools.ietf.org/html/rfc5869
- **WuzAPI (whatsmeow):** https://github.com/tulir/whatsmeow
- **ActiveStorage Rails:** https://guides.rubyonrails.org/active_storage_overview.html

---

## Contato para Suporte

Se após seguir este documento o problema persistir:

1. Verificar versão do WuzAPI (pode ter mudado protocolo)
2. Verificar se WhatsApp atualizou algoritmo de criptografia
3. Verificar logs detalhados: `tail -f log/sidekiq.log`
4. Buscar por issues no repo do whatsmeow

---

> **Nota:** Este documento foi criado após resolver um problema que levou várias horas de debug.
> A causa raiz era dupla:
>
> 1. **Serialização JSON de binários** no Sidekiq
> 2. **Algoritmo de decriptografia incorreto** (usava padding, deveria ser sem padding)
