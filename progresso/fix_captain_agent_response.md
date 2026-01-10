# Fix: Captain Agent Não Respondia Corretamente

**Data:** 2026-01-07
**Autor:** Antigravity AI

---

## Problema

O Captain Agent estava retornando `conversation_handoff` ou mensagens de erro genéricas ao invés de responder às perguntas dos usuários corretamente.

## Diagnóstico

### 1. API Key Inválida no `.env`

A chave `OPENAI_API_KEY` no arquivo `.env` estava inválida/revogada:

```
OPENAI_API_KEY=sk-proj-l5XCl-...iu5U  # INVÁLIDA
```

Resultado: Erro `UnauthorizedError: Incorrect API key provided`

### 2. Método `RubyLLM.configuration` Errado

O código estava usando `RubyLLM.configuration` que não existe. O correto é `RubyLLM.config`:

```ruby
# ERRADO
RubyLLM.configuration.openai_api_key

# CORRETO
RubyLLM.config.openai_api_key
```

### 3. FAQs Sem Embeddings

Os FAQs cadastrados não tinham embeddings gerados, tornando-os invisíveis para a busca semântica:

```ruby
# Verificação
faq.embedding.present?  # => false
```

---

## Solução

### 1. Atualizar API Key no `.env`

Substituir a chave inválida pela chave válida:

```bash
# Arquivo: .env
OPENAI_API_KEY=sk-proj-xKi75fs_...  # NOVA CHAVE VÁLIDA
```

### 2. Corrigir `AgentRunnerService`

Arquivo: `enterprise/app/services/captain/assistant/agent_runner_service.rb`

```ruby
def with_assistant_api_key
  api_key = @assistant.api_key.presence
  original_key = RubyLLM.config.openai_api_key  # CORRIGIDO

  if api_key.present?
    RubyLLM.config.openai_api_key = api_key  # CORRIGIDO
    Rails.logger.info "[Captain V2] Using assistant API key: #{api_key[0..15]}..."
  end

  yield
ensure
  RubyLLM.config.openai_api_key = original_key if api_key.present?  # CORRIGIDO
end
```

### 3. Gerar Embeddings para FAQs

Executar manualmente o job de geração de embeddings:

```ruby
Captain::AssistantResponse.approved.find_each do |faq|
  if faq.embedding.nil?
    Captain::Llm::UpdateEmbeddingJob.perform_now(faq, "#{faq.question}: #{faq.answer}")
  end
end
```

### 4. Recriar Containers

O `docker-compose restart` não recarrega variáveis de ambiente. É necessário recriar:

```bash
docker-compose up -d rails sidekiq
```

---

## Validação

1. Verificar chave no container:

```bash
docker-compose exec rails bundle exec rails runner 'puts RubyLLM.config.openai_api_key[0..20]'
# Output esperado: sk-proj-xKi75fs_ntsx6
```

2. Verificar embeddings:

```bash
docker-compose exec rails bundle exec rails runner 'puts Captain::AssistantResponse.approved.last.embedding.present?'
# Output esperado: true
```

3. Testar no Playground com uma pergunta que existe nos FAQs

---

## Arquivos Modificados

| Arquivo                                                             | Alteração                                                        |
| ------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `.env`                                                              | Atualizada `OPENAI_API_KEY`                                      |
| `enterprise/app/services/captain/assistant/agent_runner_service.rb` | Corrigido `RubyLLM.config` e adicionado `with_assistant_api_key` |
| `docker-compose.yaml`                                               | Corrigido volume do Postgres (`/var/lib/postgresql/data`)        |

---

## Lições Aprendidas

1. **Sempre validar API key via curl** antes de assumir problemas no código
2. **`docker-compose restart` ≠ `docker-compose up -d`** para mudanças de `.env`
3. **Embeddings são obrigatórios** para busca semântica funcionar
4. **Verificar API da gem** antes de usar métodos (ex: `RubyLLM.config` vs `RubyLLM.configuration`)
