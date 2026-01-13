# Fix: Galeria de Mídia em Branco (Media Gallery)

## Contexto

A página "Galeria de Mídia" (`/captain/assets`) estava carregando totalmente em branco para o usuário.
Inicialmente suspeitou-se de erro no componente Vue ou na API, mas após correções iniciais, o problema persistiu.

## Sintomas

- Página branca.
- Console do navegador exibia: `SyntaxError: Not allowed nest placeholder` vindo de `vue-i18n` (useBranding).

## Causa Raiz

O arquivo de tradução `pt_BR/integrations.json` continha uma string com sintaxe de interpolação inválida para o Vue I18n:
`"DESCRIPTION": "Envie imagens e referencie nos prompts usando {{ media.chave }}."`

O par de chaves duplas `{{ }}` é interpretado pelo framework como um placeholder de variável. Como `media.chave` não era uma variável passada, e a sintaxe estava solta, causava o crash da renderização.

## Solução

1. **Frontend (Defensivo)**: Adicionado _Optional Chaining_ (`?.`) e valores padrão (`|| 0`) no componente `Index.vue` para evitar erros caso a Store demore a carregar.
2. **I18n (Correção)**: Escape das chaves no arquivo de tradução JSON para serem tratadas como literal string.
   - De: `{{ media.chave }}`
   - Para: `{'{{'} media.chave {'}}'}`

## Arquivos Alterados

- `app/javascript/dashboard/routes/dashboard/captain/assets/Index.vue`
- `app/javascript/dashboard/i18n/locale/pt_BR/integrations.json`

## Validação

O erro de sintaxe sumiu do console e a página voltou a renderizar a interface corretamente.
