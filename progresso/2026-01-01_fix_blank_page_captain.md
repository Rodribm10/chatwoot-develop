# Nota de Progresso: Resolução de Blank Page (Tela Branca) no Captain V2

## Objetivo

Resolver a falha catastrófica de interface (blank page) que impedia a utilização das configurações do assistente Captain V2.

## Contexto

Após a introdução de campos para Multi-LLM e novas abas de "Skills", a interface começou a apresentar uma tela branca. O erro era causado por acessos a propriedades de objetos `null` no ciclo de vida inicial do Vue, antes dos dados serem hidratados pelo Vuex.

## Passos Realizados

1.  **Debug de Fluxo**: Identificado que o `AssistantsIndexPage.vue` tentava dar um `.find()` em um estado do Vuex ainda não inicializado.
2.  **Implementação de Null-Safety**:
    - Adicionado `optional chaining` (`?.`) em templates onde `assistant.name` era acessado.
    - Adicionados checks de saída antecipada (`if (!assistant) return`) em observadores (watchers) e funções de atualização de estado.
3.  **Correção de Componentes**:
    - O componente `SelectMenu` exigia a prop `label` em novas versões, causando crash silencioso se estivesse ausente. A prop foi restaurada com as chaves de tradução corretas.
4.  **Roteamento**: Re-enquadramento das rotas no `captain.routes.js` para garantir que o `navigationPath` seja resolvido corretamente.

## Arquivos Alterados

- `app/javascript/dashboard/routes/dashboard/captain/pages/AssistantsIndexPage.vue`
- `app/javascript/dashboard/routes/dashboard/captain/assistants/settings/Settings.vue`
- `app/javascript/dashboard/components-next/captain/pageComponents/assistant/settings/AssistantBasicSettingsForm.vue`
- `app/javascript/dashboard/routes/dashboard/captain/captain.routes.js`
- `app/javascript/dashboard/i18n/locale/en/integrations.json` (Adição de chaves de tradução)

## Validação

- Navegação direta para `/captain/assistants/1/settings` agora carrega sem erros.
- Navegação via sidebar para "Skills" (Tools) funciona conforme o esperado.
- Console do browser limpo de erros de `undefined`.

## Rollback

Basta reverter os checks de segurança e a prop `label` do `SelectMenu`, embora não seja recomendado, pois a abordagem atual segue o padrão defensivo do projeto.
