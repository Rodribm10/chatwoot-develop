# Solução: FAQ não respondendo (Embeddings Ausentes)

## 🚨 Problema

A IA não estava usando as informações do Knowledge Base (FAQs) para responder, mesmo com as perguntas cadastradas.
Causa: A coluna `embedding` nas tabelas de resposta estava `NULL`.

## 🔍 Diagnóstico

- As FAQs foram criadas enquanto o sistema `sidekiq` estava crashando (devido aos erros anteriores de API Key/Sintaxe).
- O job assíncrono `Captain::Llm::UpdateEmbeddingJob` que gera os vetores nunca rodou.
- Sem vetores, a busca semântica (`SearchDocumentationService`) não encontra nada.

## 🛠️ Solução

Rodei um script via Console para forçar a geração de embeddings para os itens pendentes:

```ruby
Captain::AssistantResponse.where(embedding: nil).find_each do |r|
  Captain::Llm::UpdateEmbeddingJob.perform_now(r, "#{r.question}: #{r.answer}")
end
```

## ✅ Resultado

- Banco de dados verificado: `has_embedding` agora é `true`.
- A IA agora deve conseguir encontrar "Qual valor da suite".
