# Ativação da Camada de Inteligência (Jasmine) em Produção

## Data: 2026-01-14

## Objetivo

Ativar a camada de decisão inteligente (Jasmine) para processar conversas reais em todos os canais de atendimento (Wuzapi, Widget, etc.).

## Contexto

A Jasmine é uma camada de roteamento que antecede a resposta do assistente. Ela analisa a mensagem do usuário e decide se a resposta deve ser:

1.  **Direta:** A resposta é gerada pelo LLM principal, usando FAQs, documentos e persona.
2.  **Via Ferramenta/Cenário:** A solicitação é delegada a um sub-agente especializado (como a Daniela Reservas) que pode executar ações.

## O que foi alterado

### Arquivo: `enterprise/app/services/captain/llm/assistant_chat_service.rb`

- **Antes:** A condição `if @conversation.present? && false` impedia a execução da Jasmine em qualquer conversa real.
- **Depois:** A condição foi alterada para `if @conversation.present?`, ativando a Jasmine para todas as conversas com contexto.

### Arquivo: `enterprise/app/services/captain/llm/jasmine_brain.rb`

- Removidos os comandos `puts` de depuração para manter o terminal de produção limpo.

## Canais Afetados

- ✅ Wuzapi (WhatsApp)
- ✅ Widget (Chat do Site)
- ✅ Qualquer outro inbox com Captain AI habilitado
- ❌ Playground (continua em modo direto, sem Jasmine)

## Como Reverter (Rollback)

Em caso de problemas, edite o arquivo `assistant_chat_service.rb` e adicione `&& false` de volta à condição:

```ruby
if @conversation.present? && false
```

## Validação

O fluxo completo foi testado com sucesso na Unidade Samambaia:

1.  Jasmine identificou a intenção de reserva.
2.  Delegou para a Daniela.
3.  Daniela executou as ferramentas de disponibilidade, criação de reserva e geração de Pix.
4.  O Pix real foi gerado e entregue conversacionalmente no chat.
