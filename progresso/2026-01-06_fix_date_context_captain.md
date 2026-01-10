# Fix: Injeção de Data no Contexto do Captain

## Objetivo
Corrigir a incapacidade do agente "Capitão" (e seus cenários) de saber a data atual, o que levava a respostas incorretas sobre o dia da semana ou a data corrente.

## Contexto
O usuário relatou que o Capitão não sabia que dia era hoje (pensava ser quinta-feira quando era terça). A análise revelou que os prompts de sistema (System Prompts) e templates Liquid não recebiam nenhuma informação temporal.

## Passos Realizados

1.  **Captain::Assistant (Agent V2)**:
    *   Arquivo: `enterprise/app/models/captain/assistant.rb`
    *   Mudança: Adicionado `current_date` ao método `prompt_context`, formatado como `Time.zone.today.strftime('%A, %B %d, %Y')`.

2.  **Captain::Scenario (Agent V2)**:
    *   Arquivo: `enterprise/app/models/captain/scenario.rb`
    *   Mudança: Adicionado `current_date` ao método `prompt_context`.

3.  **Templates Liquid**:
    *   Arquivos: `enterprise/lib/captain/prompts/assistant.liquid`, `enterprise/lib/captain/prompts/scenario.liquid`
    *   Mudança: Adicionada a linha `Today is {{ current_date }}.` na seção "Current Context".

4.  **Copilot Chat Service**:
    *   Arquivo: `enterprise/app/services/captain/copilot/chat_service.rb`
    *   Mudança: Injeção de uma mensagem de sistema adicional contendo `Today is ...` no método `build_messages`.

5.  **Assistant Chat Service (Legacy/Alternative)**:
    *   Arquivo: `enterprise/app/services/captain/llm/assistant_chat_service.rb`
    *   Mudança: Injeção de uma mensagem de sistema adicional contendo `Today is ...` na inicialização do serviço.

## Código/Arquivos Alterados
- `enterprise/app/models/captain/assistant.rb`
- `enterprise/app/models/captain/scenario.rb`
- `enterprise/lib/captain/prompts/assistant.liquid`
- `enterprise/lib/captain/prompts/scenario.liquid`
- `enterprise/app/services/captain/copilot/chat_service.rb`
- `enterprise/app/services/captain/llm/assistant_chat_service.rb`

## Como Validar
Interagir com o agente Capitão (em modo Copilot ou Autônomo) e perguntar "Que dia é hoje?". O agente deve responder com a data correta baseada no servidor (Time.zone.today).
