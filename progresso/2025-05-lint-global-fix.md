# Nota de Resolução: Correção Global de Lint e Qualidade (Maio 2025)

## Objetivo

Resolver mais de 100 erros de linting (Frontend e Backend) e estabelecer padrões de qualidade para os módulos Jasmine e Wuzapi.

## Contexto

O projeto apresentava débitos técnicos acumulados nas novas rotas de IA (Jasmine), incluindo falta de internacionalização, erros de sintaxe no Vue (hoisting/circular dependencies) e riscos de segurança no backend Ruby.

## Passos Realizados

1.  **Frontend (Vue/ESLint)**:
    - Criação do sistema de i18n para Jasmine em `en/jasmine.json`.
    - Refatoração completa de 5 componentes (`JasmineInboxes`, `JasminePlayground`, `JasmineConfiguration`, `JasmineKnowledgeBase`, `WuzapiConfiguration`).
    - Resolução de erros de Prettier e sintaxe.
2.  **Backend (Ruby/RuboCop)**:
    - Criação de `.rubocop_todo.yml` para congelar débitos antigos.
    - Refatoração de controllers e remoção de credenciais hardcoded.
    - Identificação de vulnerabilidade crítica de SSL em `lib/wuzapi/client.rb`.

## Arquivos Principais Alterados

- `app/javascript/dashboard/i18n/locale/en/jasmine.json` (Novo sistema i18n)
- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/wuzapi/WuzapiConfiguration.vue` (Fix Hosting)
- `lib/wuzapi/client.rb` (Identificado risco SSL)
- `.rubocop_todo.yml` (Gestão de débito técnico)

## Variáveis de Ambiente

- `DEFAULT_JASMINE_DISTANCE_THRESHOLD`: Configura limite de busca RAG (Padrão: 0.35).
- `JASMINE_LLM_MODEL`: Define modelo de IA (Padrão: gpt-4o-mini).

## Como Validar ou Reverter

- **Validar Frontend**: Executar `npx eslint --ext .js,.vue [arquivos]`. Resultado esperado: 0 erros.
- **Validar Backend**: Executar `bundle exec rubocop`. Resultado esperado: Sucesso (via todo).
- **Reverter**: `git checkout` nos arquivos mencionados.
