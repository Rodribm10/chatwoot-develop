# Substituição Daniela -> Camila Reservas (Migração e Arquitetura)

**Data:** 18/01/2026
**Autor:** Antigravity (Assistant)
**Contexto:** Teste A/B e Evolução da Arquitetura de Reservas

## 1. Objetivo

Migrar a lógica de reservas que estava hardcoded na agente "Daniela Reservas" para uma nova arquitetura mais flexível baseada na agente "Camila Reservas", gerenciada via UI (Agent Manager) e com suporte a roteamento dinâmico.

O objetivo principal é permitir que o prompt e as configurações da agente de reservas sejam alterados por usuários não-técnicos (ou sem deploy), facilitando testes A/B e ajustes finos.

## 2. Mudanças Arquiteturais

### A. De Hardcoded para Database-Driven

- **Antes (Daniela):** A lógica de seleção e o prompt da Daniela eram muitas vezes dependentes de código ou arquivos estáticos difíceis de alterar em tempo de execução.
- **Depois (Camila):** A Camila é um registro completo na tabela `Captain::Scenario` (Agent Manager). Seu prompt ("Instruction") e ferramentas habilitadas vivem no banco de dados.

### B. Roteamento Dinâmico (Dynamic Routing)

Implementamos uma nova camada de decisão na `JasmineBrain` para substituir o roteamento estático.

- **Trigger Keywords:** Adicionamos o campo `trigger_keywords` no modelo `Captain::Scenario`.
- **Lógica:** A Jasmine agora consulta o banco para ver se a mensagem do usuário contém palavras-chave de algum cenário ativo. Se sim, roteia diretamente, sem passar por lógicas condicionais complexas no código Ruby.
- **Sugestão Mágica ✨:** Criamos um endpoint `/suggest_triggers` que usa LLM (configurável via env `CAPTAIN_LLM_MODEL`) para sugerir palavras-chave com base na descrição do agente.

### C. Message Debouncer (WhatsApp)

Para resolver problemas de fragmentação de mensagens (onde "Oi", "quero", "reservar" eram processadas como 3 intenções separadas), implementamos um Debouncer.

- **Funcionamento:** O sistema aguarda um buffer de tempo (ex: 15s) após a última mensagem do usuário.
- **Agregação:** Todas as mensagens recebidas nesse intervalo são concatenadas (com `\n`) e enviadas como um único bloco de texto para a IA.
- **Benefício:** A Camila recebe o contexto completo ("Oi\nquero\nreservar") e responde de forma muito mais assertiva.

## 3. Passos da Migração

1.  **Clonagem:** Criamos um script `restore_camila_prompt.rb` que clona a "Daniela Reservas" para criar a "Camila Reservas", copiando instruções e ferramentas.
2.  **Ajuste na Brain:** Alteramos `enterprise/app/services/captain/llm/jasmine_brain.rb` para priorizar o roteamento dinâmico ou apontar explicitamente para a Camila em intenções de reserva.
3.  **UI Updates:** Atualizamos o `ScenariosCard.vue` para suportar a edição de palavras-chave e a funcionalidade de sugestão mágica.
4.  **Backend Fixes:** Corrigimos o `ScenariosController` para respeitar a variável de ambiente `CAPTAIN_LLM_MODEL` (Gemini) em vez de hardcoar OpenAI.

## 4. Arquivos Relevantes Alterados

- `enterprise/app/services/captain/llm/jasmine_brain.rb`: Lógica de roteamento.
- `enterprise/app/controllers/api/v1/accounts/captain/scenarios_controller.rb`: Endpoint de sugestão e CRUD de cenários.
- `app/javascript/dashboard/components-next/captain/assistant/ScenariosCard.vue`: UI do Card de Cenário.
- `app/javascript/dashboard/i18n/locale/pt_BR/integrations.json`: Traduções (Trigger Keywords).
- `enterprise/app/jobs/captain/conversation/debounce_response_job.rb`: Job de Debounce.
- `enterprise/app/jobs/captain/conversation/response_builder_job.rb`: Lógica de agregação de mensagens no V2.

## 5. Como Validar

1.  **Verificar Agente:** Vá em "Capitão" > "Cenários" e confirme se "Camila Reservas" existe e está ativa.
2.  **Testar Roteamento:**
    - Adicione palavras-chave na Camila (ex: "reservar", "vaga").
    - Envie "Quero reservar" no Chat.
    - Verifique se a resposta vem da Camila (pode ter personalidade diferente ou logar `agent_name: Camila Reservas`).
3.  **Testar Debounce:**
    - Envie 3 mensagens rápidas.
    - Aguarde a resposta única.

## 6. Como Reverter (Rollback)

Caso a Camila apresente instabilidade:

1.  **Via UI:** Desative o cenário "Camila Reservas" no Agent Manager.
2.  **Via Código (Emergência):** Edite `jasmine_brain.rb` e reverta o apontamento manual de `consultar_camila_reservas` para `consultar_daniela_reservas` (se houver override manual).
3.  **Restaurar Prompt:** Se a Camila for corrompida, rode `bundle exec rails runner restore_camila_prompt.rb` para resetá-la ao estado original da Daniela.
