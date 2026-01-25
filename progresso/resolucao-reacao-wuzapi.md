# Resolução: Reações de Mensagem Wuzapi

Este documento detalha a implementação e correção das reações de mensagem automáticas do WhatsApp (Wuzapi). Siga este guia para restaurar a funcionalidade caso ela seja perdida ou quebrada.

## 1. Problemas e Diagnóstico

1.  **Formatação do JID (WuzapiService)**: O Wuzapi rejeitava reações enviadas apenas com o número de telefone. Foi necessário impor o formato `<numero>@s.whatsapp.net`.
2.  **Erro de Argumentos (AgentRunnerService)**: A instanciação da ferramenta `ReactToMessageTool` estava incorreta, gerando `ArgumentError`. O argumento `assistant` deve ser posicional.
3.  **Perda de Contexto (ReactToMessageTool)**: O `initialize` da ferramenta não passava `conversation` para a classe pai, fazendo com que validações falhassem silenciosamente.

## 2. Implementação de Referência (Código para Restauração)

### A. Service do Provedor Wuzapi

**Arquivo**: `app/services/whatsapp/providers/wuzapi_service.rb`
**Método Crítico**: `send_reaction_message`

Certifique-se de que a lógica de formatação do JID esteja presente dentro do `else` do prefixo `me:`.

```ruby
def send_reaction_message(phone_number, message_id, reaction_emoji)
  return if phone_number.blank? || message_id.blank?

  # ... (lógica de seleção de canal)

  use_me_prefix = phone_number == @whatsapp_channel.validate_provider_config['phone_number']
  normalized_phone = phone_number

  if use_me_prefix
    normalized_phone = "me:#{normalized_phone}" unless normalized_phone.start_with?('me:')
    message_id = "me:#{message_id}" if message_id.present? && !message_id.start_with?('me:')
  else
    # [FIX] Enforce JID format for customer numbers
    clean_number = normalized_phone.split('@').first
    normalized_phone = "#{clean_number}@s.whatsapp.net"
  end

  Rails.logger.info "[WuzapiService] Attempting reaction: phone=#{normalized_phone}, msg_id=#{message_id}, emoji=#{reaction_emoji}"
  client.send_reaction(normalized_phone, reaction_emoji, message_id)
end
```

> [!IMPORTANT] > **Correção (24/01)**: É necessário remover o prefixo `WAID:` do ID da mensagem, caso contrário o Wuzapi rejeita silenciosamente.
> Adicione logo antes do `if use_me_prefix`:
>
> ```ruby
> # Strip WAID prefix if present
> message_id = message_id.gsub(/^WAID:/, '') if message_id.present?
> ```

### B. Lógica de Decisão e Classificação (AgentRunnerService)

**Arquivo**: `enterprise/app/services/captain/assistant/agent_runner_service.rb`
**Método Crítico**: `check_and_react_to_message`

Este método contém a lógica de "curto-circuito" que detecta intenções (agradecimento, saudação, atenção) e reage diretamente antes de chamar a IA principal.

```ruby
def check_and_react_to_message(message)
  text = message.to_s.strip.downcase
  return nil if text.blank?

  # 1. Helper simplificado de detecção (não regex complexo)
  only_emoji = text.gsub(/[\s\p{Emoji}]/u, '').empty? && text.match?(/\p{Emoji}/u)

  # 2. Categorias e Palavras-chave
  keywords = {
    thanks: %w[obrigad valeu agradeço grato thanks brigadao brigadão gratidao gratidão],
    greeting: %w[oi olá ola bom dia boa tarde boa noite e ai eaí],
    attention: %w[reserva pesquisar pesquisa busca buscar verificar checar olhada olho disponibilidade]
  }

  matched_category = nil

  # 3. Classificação
  keywords.each do |category, words|
    if words.any? { |w| text.include?(w) }
      matched_category = category
      break
    end
  end

  matched_category = :thanks if matched_category.nil? && only_emoji

  if matched_category
    Rails.logger.info "[Captain V2] Detected #{matched_category}. Executing ReactToMessageTool directly."

    # 4. Mapa de Emojis por Contexto
    emoji_map = {
      thanks: ['❤️', '🙏', '🥰', '😍', '🤜🤛'],
      greeting: ['😀', '👋', '🙂', '🤠', '🙋‍♂️', '🙋‍♀️'],
      attention: ['👀', '🧐', '🕵️', '📝', '🔎']
    }

    selected_emoji = emoji_map[matched_category].sample || '❤️'

    begin
      # [FIX] Instanciação correta: assistant é POSICIONAL
      tool = Captain::Tools::ReactToMessageTool.new(
        @assistant,
        user: @conversation.contact,
        conversation: @conversation
      )
      tool.execute(emoji: selected_emoji)
    rescue StandardError => e
      Rails.logger.error "[Captain V2] Failed to execute ReactToMessageTool: #{e.message}"
      return nil
    end

    return {
      'response' => "De nada! #{selected_emoji}",
      'reasoning' => "Auto-reaction triggered by #{matched_category} detection",
      'agent_name' => @assistant.name
    }
  end

  nil
end
```

### C. Ferramenta de Reação (ReactToMessageTool)

**Arquivo**: `enterprise/app/services/captain/tools/react_to_message_tool.rb`
**Correção Crítica**: Método `initialize` e `execute` com logs.

```ruby
class ReactToMessageTool < BaseTool
  # ... (name, description, schema)

  def initialize(assistant, user: nil, conversation: nil)
    # [FIX] Repassar conversation para o super é CRUCIAL
    super(assistant, user: user, conversation: conversation)
  end

  def execute(*args, **params)
    actual_params = resolve_params(args, params)
    emoji = actual_params[:emoji]

    # Validações com logs de erro explícitos
    unless @conversation.present?
      Rails.logger.warn "[ReactToMessageTool] Failure: No conversation context"
      return error_response('Conversation not found')
    end

    last_customer_message = @conversation.messages.incoming.last
    if last_customer_message.blank?
      Rails.logger.warn "[ReactToMessageTool] Failure: No incoming message"
      return error_response('No customer message to react to')
    end

    message_external_id = last_customer_message.source_id
    if message_external_id.blank?
      Rails.logger.warn "[ReactToMessageTool] Failure: Message #{last_customer_message.id} has no source_id"
      return error_response('Message has no external ID')
    end

    Rails.logger.info "[ReactToMessageTool] Reacting with #{emoji}"
    create_reaction_message(last_customer_message, emoji, message_external_id)

    { success: true, message: "Reacted with #{emoji}" }.to_json
  rescue StandardError => e
    # ...
  end
  # ...
end
```

### D. Lição Aprendida: ID de Reação

**Arquivo**: `lib/wuzapi/client.rb` & `app/services/whatsapp/providers/wuzapi_service.rb`

Houve uma confusão inicial onde tentamos alterar o payload para usar `MessageId` (como nas respostas), mas a documentação e testes confirmaram que a chave correta para **Reações** é `Id`.

O problema real era o **valor** do ID:

- O Chatwoot gera IDs internos com prefixo `WAID:` (ex: `WAID:XYZ123`).
- A API Wuzapi espera o ID limpo (ex: `XYZ123`).
- **Solução Definitiva**: Manter a chave `Id` no Client e aplicar o `.gsub(/^WAID:/, '')` no Service (visto na seção B).

## 3. Passo a Passo de Recuperação

1.  **Verifique os Logs**: Busque por `[Captain V2]`, `[ReactToMessageTool]` ou `[WuzapiService]` para identificar onde a cadeia quebrou.
2.  **Restaure o Código**: Copie e cole os blocos de código acima nos respectivos arquivos.
3.  **Teste**: Envie "Obrigado" ou "Oi" para o bot e observe se a reação ocorre e se o emoji corresponde ao contexto.
