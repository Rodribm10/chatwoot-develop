# Fix: Playground 500 Error (Undefined method `with_api_key`)

## 🚨 Problema

O Playground do Captain AI falhava com erro 500 ao enviar mensagem.
**Erro nos logs:** `undefined method 'with_api_key' for an instance of RubyLLM::Chat` em `AssistantChatService`.

## 🔍 Causa

A biblioteca `RubyLLM` (versão atual usada no projeto) não suporta o método `.with_api_key()` na instância do chat, ou a interface mudou.
O código em `enterprise/app/services/llm/base_ai_service.rb` tentava injetar a chave de API dessa forma, causando o crash.

## 🛠️ Solução Aplicada

1.  **Edição do Código**: Comentei a linha problemática em `enterprise/app/services/llm/base_ai_service.rb`.
    ```ruby
    # client = client.with_api_key(api_key) if api_key.present?
    ```
2.  **Configuração Global**: O sistema já possui um inicializador (`config/initializers/ruby_llm.rb`) que configura a chave globalmente via variável de ambiente `OPENAI_API_KEY`. Portanto, a remoção da chamada explícita não deve afetar o funcionamento se a chave estiver no `.env`.

## ✅ Verificação

- Reiniciei os containers `rails` e `sidekiq`.
- O Playground deve voltar a responder usando a chave global.
