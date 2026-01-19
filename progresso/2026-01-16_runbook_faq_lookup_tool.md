# Runbook: FAQ Lookup (Captain/Jasmine)

**Data:** 16/01/2026  
**Objetivo:** documentar como o FAQ Lookup funciona apos o ajuste, para facilitar diagnostico e correcoes futuras.

## 1. Fluxo esperado (resumo)

1) O agente chama a ferramenta `faq_lookup` com um `query` (ou sem `query`).
2) A ferramenta resolve o melhor texto de busca:
   - usa `last_user_message` do contexto, se existir e nao for saudacao;
   - senao usa o `query` passado, se valido;
   - senao busca a ultima mensagem do usuario na conversa.
3) A busca ocorre em `@assistant.responses.approved.search(query)`.
4) Retorna respostas formatadas ou `"No relevant FAQs found for: <query>"`.

## 2. Onde a logica vive

- `enterprise/lib/captain/tools/faq_lookup_tool.rb`
- Logs de debug: `log/faq_debug.log`

## 3. Requisitos de contexto

Para funcionar de forma confiavel, pelo menos um destes deve existir:
- `state[:last_user_message]` no `tool_context`.
- `args[:query]` ou `args['query']` valido.
- `conversation.id` disponivel no contexto (para fallback).

## 4. Como o `query` e resolvido

1) **Preferencia 1:** `state[:last_user_message]` (nao-saudacao).  
2) **Preferencia 2:** `query` explicito (nao-saudacao).  
3) **Fallback:** ultima mensagem recebida na conversa:
   - pega as 10 ultimas mensagens **incoming**, nao privadas;
   - ignora saudacoes; retorna a mais recente valida.

**Saudacoes ignoradas:** `oi`, `ola`, `bom dia`, `boa tarde`, `boa noite` (normalizadas).

## 5. Logs importantes

Arquivo: `log/faq_debug.log`

Entradas esperadas:
- `FaqLookupTool CALLED with args: ...`
- `resolve_query: Using state[:last_user_message] = '...'`
- `resolve_query: Using explicit query = '...'`
- `resolve_query: Using fallback = '...'`
- `SUCCESS: Found X results for '...'`
- `RETURN: No results for '...'`
- `RETURN: No query provided`

## 6. Checklist rapido se quebrar

1) Verifique se o tool esta registrado como `faq_lookup`.
2) Confirme que o `tool_context` possui `last_user_message` ou `conversation.id`.
3) Garanta que o `query` nao e apenas saudacao (ele sera descartado).
4) Verifique `log/faq_debug.log` para confirmar o texto usado na busca.
5) Valide se existem `responses.approved` no assistente.

## 7. Problemas comuns e acoes

**Sintoma:** retorna sempre "No relevant FAQs found".  
**Causas provaveis:**
- `query` vazio (somente saudacao).
- nenhum `approved` response para o assistente.
- contexto sem `conversation.id`.

**Acoes:**
- conferir logs do `faq_debug.log`;
- testar com `query` explicito e nao-saudacao;
- validar se os embeddings/indices do FAQ estao ok.

