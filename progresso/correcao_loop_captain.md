# Correção de Loop de Resposta no Captain

**Objetivo:**
Corrigir o comportamento onde o bot entrava em loop ("responder tudo errado" ou repetir boas-vindas) por receber o input do usuário duplicado no histórico.

**Contexto:**
O método `previous_messages` utilizava `offset(1)` para pular a mensagem atual, mas a ordenação padrão (`created_at ASC`) fazia com que ele pulasse a _primeira_ mensagem da conversa em vez da última. Isso incluía a mensagem atual no histórico enviado para a IA.

**Passos Realizados:**

1. Análise do `processor_service.rb`.
2. Identificação da falha no uso de `offset(1)`.
3. Refatoração para consulta explícita excluindo o ID atual.

**Arquivos Alterados:**

- `lib/integrations/captain/processor_service.rb`

**Código Principal (Diff):**

```ruby
# Antes
conversation.messages.where(...).offset(1).find_each

# Depois
conversation.messages.where('id < ?', current_message_id).reorder(created_at: :desc).limit(20)
```

**Como Validar:**

- Monitorar logs em produção ou testar enviar mensagem para o bot.
- Verificar se a resposta não repete o input ou reseta o contexto.

**Como Reverter:**
Voltar o arquivo `lib/integrations/captain/processor_service.rb` para o estado anterior.
