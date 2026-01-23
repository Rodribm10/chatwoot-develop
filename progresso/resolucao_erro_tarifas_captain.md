# Resolução de Erro: Captain Pricing (CheckAvailabilityTool) - 22/01/2026

## 1. O Problema

O usuário recebia a mensagem "Estou com um erro no meu sistema" ou "Não encontrei tarifas" ao buscar preços (ex: "preço hidro") no Playground ou via WhatsApp.

## 2. Diagnóstico Técnica

Ao analisar os logs (`log/tool_debug.log`), identificamos um **CRITICAL ERROR**:

```
undefined method 'account_id' for nil:NilClass
```

Isso ocorria na linha:

```ruby
pricing_scope = Captain::Pricing.where(account_id: @conversation.account_id)
```

**Causa Raiz:**
A ferramenta `CheckAvailabilityTool` assumia que sempre existiria um objeto `@conversation`.

- No **WhatsApp** (produção), geralmente existe uma conversa persistida.
- No **Playground** ou testes diretos, a variável `@conversation` pode chegar `nil` (nula), pois o contexto é volátil.
- Ao tentar acessar `@conversation.account_id`, o sistema quebrava (Crash), retornando a mensagem genérica de erro.

## 3. A Solução Implementada

Alteramos o código para ser resiliente. Se não houver conversa, usamos o ID da conta do próprio Assistente (`@assistant`), que sempre existe.

**Arquivo:** `enterprise/app/services/captain/tools/check_availability_tool.rb`

```ruby
# ANTES (Quebrava se @conversation fosse nil)
account_id = @conversation.account_id

# DEPOIS (Correção Robusta)
account_id = @conversation&.account_id || @assistant&.account_id
```

## 4. Requisitos de Configuração (Dados)

Para que a tarifa seja encontrada, ela precisa seguir estas regras no Banco de Dados (`Captain::Pricing`):

1.  **Account ID:** Deve ser idêntico ao da conta do bot (ex: ID 1).
2.  **Inbox ID (CRÍTICO):**
    - Se `inbox_id` for `nil` (vazio): A tarifa é **GLOBAL** e funciona para qualquer canal (WhatsApp, Web, API, Playground). **Recomendado para testes.**
    - Se `inbox_id` estiver preenchido: A tarifa só será encontrada se a conversa vier _exatamente_ daquele inbox.
3.  **Nome da Suíte (Fuzzy Match):**
    - O sistema usa busca aproximada (`ILIKE`).
    - Exemplo: Se cadastrar "Spa-Hidromassagem", buscar por "hidro", "massagem" ou "spa" irá funcionar.

## 5. Como Identificar e Corrigir no Futuro

Se o erro voltar ("Estou com um erro no meu sistema" ou tarifa não encontrada):

1.  **Verifique os Logs:**
    Execute no terminal:

    ```bash
    tail -f log/tool_debug.log
    ```

    Procure por `CRITICAL ERROR` ou `PRICING COUNT`.

2.  **Verifique se a Tarifa Existe:**
    Se o log mostra `PRICING COUNT: 0`, a tarifa não está no banco para aquela conta.
    Se o log mostra tarifas (ex: `PRICING COUNT: 30`) mas falha em achar a sua, verifique o nome (`suite_category`) e se o `inbox_id` não está restringindo o acesso.

3.  **Reinicie o Serviço:**
    Sempre que alterar código Ruby (como models ou services), reinicie os processos:
    ```bash
    make run
    # ou
    systemctl restart chatwoot-web sidekiq
    ```
