# Correção de Lint e Refatoração Backend

## Contexto

Ocorreram diversos erros de Lint (RuboCop) no backend, bloqueando o CI/CD ou a qualidade do código. Os principais arquivos afetados foram `MessageBuilder` e `ToolsController`.

## Ações Realizadas

### 1. Refatoração `MessageBuilder` (`app/builders/messages/message_builder.rb`)

- **Problema:** Classe muito longa (`Metrics/ClassLength`) e complexidade ciclomática alta.
- **Solução:**
  - Lógica de `file_type` extraída para método auxiliar `resolve_file_type`.
  - Métodos `extract_automation_rule`, `extract_in_reply_to` e `should_process_liquid?` compactados (one-liners).
  - Redução geral de linhas e complexidade.

### 2. Refatoração `ToolsController` (`app/controllers/api/v1/accounts/inboxes/jasmine/tools_controller.rb`)

- **Problema:** Métodos longos (`Metrics/MethodLength`) e complexos (`Metrics/AbcSize`).
- **Solução:**
  - Extração da validação de chave para `valid_tool_key?`.
  - Extração da busca de config para `find_config`.
  - Extração da atualização de atributos para `update_config_attributes`.
  - Extração da serialização de resposta para `success_payload`, `build_tool_hash` e `serialize_last_test`.
  - Correção de `Style/EmptyElse`.

### 3. Correções Gerais

- **Specs (`whatsapp_spec.rb`, `contact_spec.rb`):** Quebra de comentários longos para satisfazer `Layout/LineLength`.
- **StringLiterals:** Padronização para aspas simples.
- **ClassAndModuleChildren:** Formato compacto adotado onde necessário.

## Validação

- **RuboCop:** 0 ofensas.
- **RSpec:** 0 falhas nos testes unitários das classes afetadas.

## Como Reverter

Checkouts nos arquivos originais:

```bash
git checkout app/builders/messages/message_builder.rb
git checkout app/controllers/api/v1/accounts/inboxes/jasmine/tools_controller.rb
git checkout spec/models/channel/whatsapp_spec.rb
git checkout spec/models/contact_spec.rb
```
