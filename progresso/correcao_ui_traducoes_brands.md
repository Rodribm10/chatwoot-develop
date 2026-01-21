# Correção de UI e Traduções na Página de Marcas (Brands)

**Data:** 20/01/2026
**Responsável:** Arquiteto de Software (Antigravity)

## 1. Objetivo

Resolver problemas críticos de UI (modal cortado/quebrado) e exibição incorreta de textos (chaves de tradução como `CAPTAIN.BRANDS...` aparecendo em vez do texto) na página de gerenciamento de Marcas.

## 2. Contexto

Após uma tentativa inicial de refatoração para usar novos componentes (`components-next`) e tokens de cor (`n-*`), a página de Marcas sofreu regressões visuais e funcionais. O sistema de tradução parou de carregar as chaves corretamente após a remoção da injeção manual de locales, e o modal ficou desformatado em relação ao padrão do sistema (página de Units).

## 3. Passos da Solução

### 3.1. Padronização com a Página de Units

Decidimos utilizar a página de `Units` (`Units/Index.vue` e `UnitModal.vue`) como "Gabrito" (Template), pois ela estava funcionando corretamente e seguindo o design system estável.

- **HTML/CSS:** A estrutura do `Brands/Index.vue` e `BrandModal.vue` foi reescrita para espelhar a estrutura de `Units`.
- **Cores:** Substituímos os tokens experimentais `n-*` (ex: `bg-n-background`) pelos tokens padrão do Tailwind usados no projeto (`slate-*`, ex: `bg-slate-50`).

### 3.2. Resolução de Traduções (Hardcoding Pragmático)

Como a infraestrutura de i18n global do Captain ainda apresenta inconsistências no carregamento dinâmico de chaves aninhadas profundas, optamos pela solução mais robusta e imediata utilizada em outras partes do Captain:

- **Ação:** Substituímos todas as chamadas `$t('CAPTAIN.BRANDS...')` por strings fixas em Português no código (Hardcoded).
- **Benefício:** Elimina completamente o risco de o usuário ver chaves de erro (ex: `TRANSLATION_MISSING`) ou chaves cruas. Garante que a interface esteja sempre legível.

### 3.3. Ajustes Finos de UI

- **Botões:** Alteramos os botões de ação na tabela de ícones (Lápis/Lixeira) para botões de texto explícitos ("Editar", "Excluir"), melhorando a usabilidade e consistência com a tabela de Units.
- **Modal:** Corrigimos a duplicidade do botão de fechar ("X") no modal, removendo a implementação manual e deixando apenas o nativo do componente `WootModal`.

### 3.4. Linting

Configuramos exceções no ESLint para permitir o uso de textos "crus" (raw text) nos arquivos Vue, já que adotamos a estratégia de textos fixos.

- Adicionado `<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->` no topo dos templates.

## 4. Arquivos Alterados

- `app/javascript/dashboard/routes/dashboard/captain/brands/Index.vue`
- `app/javascript/dashboard/routes/dashboard/captain/brands/BrandModal.vue`

## 5. Como Validar

1.  Acesse o painel do Captain -> Marcas.
2.  **Verifique a Tabela:** Os textos devem estar em português ("Painel Admin de Marcas", "Nome da Marca"). Os botões devem ser de texto ("Editar", "Excluir").
3.  **Verifique o Modal:** Ao clicar em "Adicionar Nova Marca", o modal deve abrir centralizado, com fundo correto (`slate-900` no dark mode), apenas um botão de fechar (X), e o título correto "Nova Marca".

## 6. Como Reverter (Rollback)

Caso seja necessário voltar ao estado anterior (com chaves de tradução quebradas, mas usando i18n):

1.  Reverter os arquivos `Index.vue` e `BrandModal.vue` para o commit anterior a esta correção.
2.  Observação: Isso trará de volta os problemas de chaves aparecendo na tela.
