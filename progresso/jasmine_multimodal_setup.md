# Integração Multimodal Jasmine (Captain Engine)

## Visão Geral

Este documento detalha a arquitetura e configuração da integração multimodal (Visão e Áudio) para a assistente Jasmine no Chatwoot (versão Enterprise). A Jasmine utiliza o motor `Captain` para geração de respostas e orquestração de ferramentas.

## Arquitetura

### Fluxo de Processamento

1. **Entrada**: Mensagem do usuário com anexo (Imagem ou Áudio).
2. **Webhooks/Jobs**: O Chatwoot recebe o anexo.
3. **Trigger de Análise**:
   - O `Captain::Conversation::ResponseBuilderJob` é acionado.
   - Antes de gerar a resposta, ele invoca o `Jasmine::MediaAnalyzerService`.
   - **Correção Crítica**: O job itera sobre **todas** as novas mensagens do lote, não apenas a última, garantindo que imagens seguidas de texto sejam processadas.
4. **Serviços de Análise**:
   - **Imagens**: `Jasmine::VisionService` envia a imagem para o GPT-4o-mini e salva a descrição em `attachment.meta['description']`.
   - **Áudio**: `Messages::AudioTranscriptionService` utiliza o Whisper-1 para transcrever e salva em `attachment.meta['transcribed_text']`.
5. **Agregação de Prompt**:
   - `Captain::OpenAiMessageBuilderService` lê os metadados.
   - Imagens são inseridas no prompt como `[Imagem]: <descrição>`.
   - Áudios são inseridos como texto transcrito.
6. **Resposta**: O LLM gera a resposta com base no contexto completo.

## Configuração Necessária

### Variáveis de Ambiente

- `OPENAI_API_KEY`: Necessária para Vision (GPT-4o) e Audio (Whisper).
- `ENABLE_CAPTAIN_INTEGRATION`: Deve estar `true`.

### Configurações de Banco de Dados (Conta)

Para que a transcrição de áudio funcione, a flag deve estar explicitamente habilitada na conta:

```ruby
# Rails Console
account = Account.find(1)
account.settings['audio_transcriptions'] = true
account.save!
```

> **Nota**: Sem essa flag, o serviço de áudio falha silenciosamente ou retorna erro de permissão.

## Solução de Problemas Comuns

### "A Jasmine diz que não consegue ver a imagem"

- **Causa 1**: O usuário enviou Imagem + Texto muito rápido.
  - **Verificação**: Verifique logs do `ResponseBuilderJob`.
  - **Solução**: Código corrigido para iterar sobre `new_messages`.
- **Causa 2**: Motor incorreto.
  - **Verificação**: Certifique-se de que está usando Jasmine via Captain (Enterprise), não a implementação comunitária básica.

### "A Jasmine não ouve o áudio"

- **Solução**: Ativar a flag `audio_transcriptions`.
- **Status**: ✅ Verificado (24/01). Funcional após ativação da flag e restart do Sidekiq.
  > [!IMPORTANT]
  > Após alterar essa configuração no console, é **obrigatório reiniciar o Sidekiq** para que a mudança surta efeito, pois as configurações da conta podem ser cacheadas pelos workers.
- **Teste Rápido (Console)**:
  ```ruby
  att = Attachment.where(file_type: :audio).last
  svc = Jasmine::MediaAnalyzerService.new(message: att.message)
  svc.send(:analyze_audio)
  puts att.reload.meta
  # Esperado: {"transcribed_text"=>"..."}
  ```

## Referências de Código

- `enterprise/app/jobs/captain/conversation/response_builder_job.rb`: Orquestrador principal.
- `enterprise/app/services/captain/open_ai_message_builder_service.rb`: Montador de prompt multimodal.
- `app/services/jasmine/vision_service.rb`: Cliente Vision.
- `enterprise/app/services/messages/audio_transcription_service.rb`: Cliente Whisper (Legacy wrapper).
