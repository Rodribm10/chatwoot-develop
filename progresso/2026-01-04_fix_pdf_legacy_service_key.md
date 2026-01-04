# Solução: PDF não processado (Erro 401 / Chave API)

## 🚨 Problema

Upload de documentos PDF falhava silenciosamente ou ficava preso em `in_progress`.
Ao tentar processar manualmente, ocorria erro `401 Unauthorized`.

## 🔍 Diagnóstico

1.  **Chave Válida:** Testes com `curl` confirmaram que a chave `sk-proj-...` no `.env` estava correta e tinha permissões.
2.  **Serviço Legado:** O Chatwoot usa um serviço separado para PDFs: `Captain::Llm::PdfProcessingService`, que herda de `Llm::LegacyBaseOpenAiService`.
3.  **Causa Raiz:** A classe `LegacyBaseOpenAiService` estava **ignorando a variável de ambiente** `OPENAI_API_KEY` e buscando uma chave antiga/inválida diretamente na tabela `installation_configs` do banco de dados (`CAPTAIN_OPEN_AI_API_KEY`).

## 🛠️ Solução

Patcheamos o arquivo `enterprise/app/services/llm/legacy_base_open_ai_service.rb` para priorizar a variável de ambiente:

```ruby
def initialize
  # Antes: Apenas banco de dados
  # Agora: Tenta ENV primeiro, fallback para banco
  api_key = ENV['OPENAI_API_KEY'] || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value

  @client = OpenAI::Client.new(
    access_token: api_key,
    # ...
  )
end
```

## ✅ Resultado

- Re-executamos o `CrawlJob` manualmente.
- O PDF foi enviado com sucesso para a OpenAI.
- O status do documento mudou para `available`.
- Embeddings estão sendo gerados.
