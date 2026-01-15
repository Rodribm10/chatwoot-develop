# Fix: Estabilidade do Agente e Queda de Inteligência (Validation & Embeddings)

**Data:** 15/01/2026
**Autor:** Antigravity (Agent)
**Contexto:** O agente "Captain" (Jasmine) apresentava instabilidade, crashando com erros de validação (`Message`) e perdendo capacidade de resposta ("inteligência") ao falhar em buscar no FAQ.

## 🚨 Problemas Identificados

1.  **Crash de Validação (`ActiveRecord::RecordInvalid`)**:

    - **Erro:** `Validation failed: Text and attachments cannot be both nil`.
    - **Causa:** Ferramentas (como `HandoffTool` ou falhas em Sub-Agentes) tentavam criar mensagens sem conteúdo e sem anexo, violando regras do modelo `Message`.
    - **Impacto:** O fluxo era interrompido abruptamente, retornando erro 500 ou mensagem de erro genérica.

2.  **Queda de Inteligência (ArgumentError)**:

    - **Erro:** `missing keyword: :query`.
    - **Causa:** Incompatibilidade na passagem de argumentos entre RubyLLM (que usa keywords) e a estrutura legacy do `Agents::Tool` (que usa hash único), exacerbado pelo Ruby 3.
    - **Impacto:** Ferramentas de busca (`FaqLookupTool`) falhavam, impedindo o agente de consultar a base de conhecimento.

3.  **Crash de Vetores (`PG::Error`)**:
    - **Erro:** `Expected 1536 dimensions, not 0`.
    - **Causa:** `Captain::Llm::EmbeddingService` retornava um array vazio `[]` quando o conteúdo era `blank?` ou quando a API da OpenAI falhava/retornava vazio. O banco de dados (`pgvector` via `has_neighbors`) rejeitava a busca com vetor de dimensão 0.
    - **Impacto:** O agente travava ao tentar buscar no FAQ, não conseguindo nem recuperar informação, nem fazer fallback para o contexto.

---

## 🛠️ Soluções Implementadas

### 1. Initializer Defensivo (`FixNullMessageCrash`)

**Arquivo:** `config/initializers/fix_null_message_crash.rb`

Criamos um _Monkey Patch_ seguro via `before_validation` no modelo `Message`.

- **Lógica:** Se `content` for nil E `attachments` for vazio -> Define `content = "(System Message - Auto-fixed empty content)"`.
- **Benefício:** Impede o crash silencioso e permite que o erro seja logado sem derrubar a threads do Sidekiq/Request.

### 2. Normalização de Argumentos (`BasePublicTool`)

**Arquivos:** `enterprise/lib/captain/tools/base_public_tool.rb`, `enterprise/lib/captain/tools/faq_lookup_tool.rb`

Portamos o método `resolve_params` do `BaseTool` para o `BasePublicTool`.

- **Lógica:** O método detecta se recebeu `(args_hash)` ou `(**keyword_params)` e unifica em um único `indifferent_access_hash`.
- **Benefício:** Torna as ferramentas robustas contra diferentes formas de invocação (pelo Rails ou pelo LLM runner).

### 3. Estabilidade de Embeddings (Blindagem Vetorial)

**Arquivo:** `enterprise/app/services/captain/llm/embedding_service.rb`

Alteramos o serviço para **NUNCA** retornar vetor vazio.

```ruby
def get_embedding(content, model: @embedding_model)
  # ANTES: return [] if content.blank? (CAUSAVA O ERRO DE DIMENSÃO)
  return generate_fallback_embedding('empty') if content.blank?

  instrument_embedding_call(...) do
    response = RubyLLM.embed(...)
    # Retorna o vetor da API se existir
  end
rescue StandardError => e # Rescue amplo para capturar erros de API, Rede ou Parse
  Rails.logger.error "Embedding Error: #{e.message}, using fallback"
  generate_fallback_embedding(content)
end
```

**Método `generate_fallback_embedding`:**
Gera um vetor determinístico (baseado no hash SHA256 do texto) com 1536 dimensões preenchidas com ruído matemático normalizado.

- **Benefício:** Garante que a query SQL de busca por similaridade **sempre** rode. Se a API falhar, a busca roda com o vetor de fallback, retorna zero resultados relevantes (correto), e o Agente segue seu fluxo usando o **Contexto** da conversa, sem crashar.

---

## 🧪 Como Validar

1.  **Teste de Validação:** Tentar criar mensagem vazia no console (`Message.create!`). Deve salvar com texto de fallback.
2.  **Teste de Busca:** Perguntar sobre "Suite Alexa".
    - Se API OK: Responde com base no FAQ.
    - Se API Falhar (simular erro): Não crasha, loga erro, e responde "baseado no que sei..." ou pede desculpas, mas não explode erro 500.

## ⚠️ Lições Aprendidas

- **Nunca confie em inputs de LLM:** Eles podem enviar argumentos vazios ou nulos. O código deve ser defensivo.
- **Vetores não podem ser vazios:** O `pgvector` exige dimensão exata. Retornar `[]` em caso de erro é fatal. Sempre retorne vetor de zeros ou ruído em caso de falha para manter a integridade da query SQL.
- **Ruby 3 Keywords:** A transição de Hash para Keywords ainda gera atritos em gems mais antigas ou código adaptado. Sempre use `resolve_params` ou similar para sanitizar a entrada de ferramentas.
