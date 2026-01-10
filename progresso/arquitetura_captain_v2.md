# Arquitetura de Agentes Captain V2: Humanização, Consistência e Sub-Agentes

**Data:** 06/01/2026
**Status:** Proposta Arquitetural
**Contexto:** Evolução do Captain para atendimento autônomo de alta fidelidade.

---

## 1. Arquitetura Hierárquica (Sub-Agentes)

Atualmente, o Captain opera muito como um "Generalista". Para evitar alucinações e melhorar a consistência, devemos adotar o padrão **Orchestrator-Workers (Orquestrador-Trabalhadores)**.

### A Estrutura Proposta

1.  **O Orquestrador (The Dispatcher/Triagem):**
    *   **Função:** Não responde ao cliente (exceto saudações simples). A única função dele é analisar a intenção e rotear para o especialista correto.
    *   **Ferramenta:** `handoff_to_sales`, `handoff_to_support`, `handoff_to_human`.
    *   **Prompt:** Extremamente rígido. "Você é um classificador. Se o cliente quer comprar, chame o agente de vendas. Se tem problema técnico, chame o suporte."

2.  **Os Especialistas (Sub-Agentes/Scenarios):**
    *   Cada `Captain::Scenario` deve ser tratado como um sub-agente isolado.
    *   **Agente de Suporte Técnico:** Tem acesso à base de conhecimento (Docs) e ferramentas de debug.
    *   **Agente de Vendas:** Tem acesso a tabela de preços e ferramentas de agendamento.
    *   **Agente de Retenção:** Especialista em empatia, acionado quando o sentimento é negativo.

### Benefício Técnico
Ao restringir o escopo de cada agente, reduzimos drasticamente a chance de alucinação. O agente de vendas *não sabe* inventar soluções técnicas porque ele não tem essa ferramenta.

---

## 2. Eliminação de Alucinações (Grounding & RAG)

A alucinação ocorre quando a IA tenta ser prestativa sem ter a informação.

### Melhorias Necessárias

1.  **Strict RAG (RAG Rígido):**
    *   No `SearchDocumentationService`, devemos retornar um "score de confiança".
    *   **Regra:** Se a confiança da busca for menor que 0.7 (exemplo), o Agente **NÃO** deve tentar responder. Ele deve acionar o `escalate_to_human` ou dizer "Preciso confirmar essa informação com um especialista humano".

2.  **Citação Obrigatória:**
    *   Forçar o modelo a incluir a fonte da resposta no JSON de saída (interno), mas não necessariamente no texto final. Se ele não conseguir citar de onde tirou a informação (ID do artigo), a resposta é descartada.

3.  **Fact-Checking Step (Passo de Verificação):**
    *   Antes de enviar a resposta ao usuário, um passo intermediário (uma "segunda passada" rápida de LLM) verifica: "A resposta gerada está contida no contexto fornecido? Sim/Não". Se Não, descarta.

---

## 3. Humanização e UX (Parecer Humano)

Ser humano não é apenas falar "olá". É sobre **timing**, **memória** e **adaptação**.

### Melhorias de Comportamento

1.  **Latência Variável (Simulação de Digitação):**
    *   Respostas instantâneas (100ms) gritam "SOU UM ROBÔ".
    *   **Implementação:** Calcular o tempo de leitura da mensagem do usuário + tempo de "pensamento" + tempo de "digitação" da resposta.
    *   *Exemplo:* Uma resposta longa deve demorar 4-6 segundos para aparecer, com o status "digitando..." ativo no Chatwoot.

2.  **Análise de Sentimento (Gatekeeper):**
    *   Antes de processar a resposta, classificar o sentimento do usuário (Irritado, Feliz, Neutro).
    *   **Regra:** Se Sentimento == `Muito Irritado`, **bypass da IA**. Transfere direto para humano. IA tentando acalmar cliente furioso geralmente piora a situação.

3.  **Memória de Longo Prazo (User Facts):**
    *   O Captain deve lembrar que o "João" usa "Linux" e prefere ser atendido à tarde.
    *   **Implementação:** Um serviço que roda em background pós-conversa (`ConversationSummarizer`) para extrair "Fatos" e salvar em `Contact Custom Attributes` ou uma tabela `ContactMemories`.
    *   No próximo chat, esses fatos são injetados no Contexto.

---

## 4. Consistência (Style Guides)

Para evitar que o agente seja super formal numa hora e use gírias na outra.

1.  **Few-Shot Prompting Dinâmico:**
    *   Em vez de apenas instruções ("Seja educado"), injetar 3 exemplos reais de ótimos atendimentos da sua empresa no prompt.
    *   *Prompt:* "Aqui estão exemplos de como respondemos nesta empresa: [Exemplo 1], [Exemplo 2]".

2.  **Playbooks Estruturados:**
    *   Utilizar o campo `playbook` do `Assistant` não apenas como texto, mas como uma máquina de estados.
    *   Se o cliente está na fase "Onboarding", o tom é encorajador. Se está em "Cobrança", o tom é firme mas educado.

---

## 5. Plano de Ação (Roadmap Técnico)

1.  **Fase 1: Estrutura (Imediato)**
    *   Refinar os `System Prompts` atuais para incluir a data (Feito) e reforçar a persona.
    *   Configurar os `Scenarios` como sub-agentes especialistas.

2.  **Fase 2: Controle (Curto Prazo)**
    *   Implementar o "Delay de Digitação" no `AgentRunnerService`.
    *   Adicionar o "Gatekeeper de Sentimento".

3.  **Fase 3: Inteligência (Médio Prazo)**
    *   Implementar o "Strict RAG" (só responder se houver documento com alta similaridade).
    *   Criar o sistema de Memória de Longo Prazo.

---

### Exemplo de Fluxo Ideal (O Sonho)

1.  **Cliente:** "Meu sistema caiu e estou perdendo dinheiro!"
2.  **Orquestrador:** Detecta sentimento negativo e palavra-chave "caiu".
    *   *Ação:* Roteia para **Agente de Emergência**.
3.  **Agente de Emergência:**
    *   Consulta status do sistema (Tool). Vê que está tudo online.
    *   Consulta memória: "Cliente usa servidor on-premise".
    *   *Resposta (com delay de 3s):* "Oi João. Verifiquei aqui e nossos servidores principais estão online. Como você usa a versão local, pode ser algo na sua rede. Quer que eu chame um técnico dedicado agora?"
