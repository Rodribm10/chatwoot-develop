# Correção de Isolamento de Preços e Contexto AI

**Data:** 23/01/2026
**Autor:** Antigravity (Arquiteto)

## Problema

O Agente Captain estava "vazando" preços globais (ex: Stilo) para inboxes específicas (ex: Inbox Teste) que não deveriam ter acesso a esses preços. Mesmo após correção, o bot continuava "alucinando" os valores antigos devido ao contexto da conversa.

## Correção Técnica

Arquivo alterado: `enterprise/app/services/captain/tools/check_availability_tool.rb`

**Mudança Crítica (Strict Mode):**

```ruby
# ANTES (Permitia fallback)
pricing_scope.where(inbox_id: [current_inbox_id, nil])

# DEPOIS (Isolamento Total)
if current_inbox_id.present?
  pricing_scope.where(inbox_id: current_inbox_id) # Zero tolerância para global
else
  pricing_scope.where(inbox_id: nil)
end
```

## Nuance de Contexto (O "Pulo do Gato")

O bot mantém histórico das últimas mensagens. Se ele "leu" um preço errado no passado, ele pode repetir esse preço da memória (alucinação) mesmo que o banco de dados já esteja corrigido.

**Solução Operacional:**
Para forçar o bot a reler o banco corretamente após uma correção de código/dados:

1. Digitar: "Reiniciar" ou "Começar de novo" (gatilhos no código).
2. **Melhor opção:** Resolver a conversa no Chatwoot (inicia novo `conversation_id`).

## Comandos Úteis

- Verificar preços no console:
  `bundle exec rails runner "Captain::Pricing.where(inbox_id: 12).each { |p| puts p.suite_category }"`
