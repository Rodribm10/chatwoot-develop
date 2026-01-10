# Plano de Evolução do Capitão (Jasmine): De Assistente a Ecossistema

**Data:** 06/01/2026
**Arquiteto:** Gemini (Senior Architect Mode)
**Status:** Em Execução (Fase de Estabilidade)

---

## 1. Objetivo Principal
Transformar o "Capitão" de um robô reativo em um **Ecossistema de Atendimento Inteligente**, focado em **Consistência de Marca (Jasmine)**, **Zero Alucinação** e **Eficiência Operacional**.

---

## 2. O que já Concluímos (Fundação)

- [x] **Consciência Temporal:** O agente agora sabe a data, dia da semana e hora exata no fuso de Brasília.
- [x] **Arquitetura de Delegação (Supervisor Pattern):**
    - A Jasmine é a orquestradora única.
    - Sub-agentes (Daniela, Maria, Jamile) operam como "Departamentos Internos" acessados via ferramentas (`consultar_...`).
    - **Motivo:** Evita a quebra de tom de voz e permite roteamento dinâmico entre vários especialistas em uma única conversa.
- [x] **Humanização de Interface:**
    - Simulação de digitação adaptativa (50ms por caractere).
    - Ativação do status "Digitando..." no Chatwoot.
- [x] **Camada de Segurança (Sentimento):**
    - Identificação de raiva/frustração no JSON de resposta.
    - Toggle no Frontend para ativar Handoff Automático para humanos em casos críticos.
- [x] **Sanitização de API:** Proteção contra chaves corrompidas e fallback de erros amigáveis.

---

## 3. Próximos Passos (O Roadmap)

### Fase 1: Zero Alucinação (Strict RAG)
- **Implementação:** Injetar um "Confidence Score" no retorno da busca de documentos.
- **Regra de Ouro:** Se a similaridade for inferior a 0.7, a IA é proibida de afirmar fatos. Ela deve usar o fallback: *"Não localizei essa informação específica agora, vou confirmar com o gerente para você"*.
- **Risco:** Tornar o robô muito "travado". Precisamos calibrar o threshold.

### Fase 2: Memória de Longo Prazo (Fact Extraction)
- **Implementação:** Um serviço pós-conversa que lê o chat e extrai fatos (ex: "O cliente prefere suíte com Alexa", "Aniversário em 10/05").
- **Ação:** Salvar esses dados automaticamente nos `Custom Attributes` do contato.
- **Benefício:** Na próxima conversa, a Jasmine já saúda o cliente com: *"Oi João, que bom te ver de novo! Quer aquela suíte Alexa que você gosta?"*.

### Fase 3: Roteamento Proativo
- **Implementação:** Melhorar o orquestrador para que ele possa consultar dois departamentos antes de responder.
- **Exemplo:** *"Vou ver as fotos com a Maria e os preços com a Daniela e já te mando tudo"*.

---

## 4. Análise de Riscos e Mitigação

1.  **Latência (Risco de Performance):**
    - *Problema:* O modelo de Delegação (Jasmine pergunta para Daniela) dobra o tempo de resposta.
    - *Mitigação:* Usar modelos mais rápidos (GPT-4o-mini ou Gemini Flash) para os sub-agentes e o modelo robusto (GPT-4o) apenas para a orquestradora.

2.  **Custo de Tokens:**
    - *Problema:* Injetar muitos blocos de contexto (Tabela de Preços) em todas as mensagens aumenta o custo.
    - *Mitigação:* Implementar cache de contexto ou usar busca vetorial (RAG) até para os preços, em vez de prompt fixo.

3.  **Perda de Contexto no Handoff Interno:**
    - *Problema:* A Daniela pode não saber o que o cliente disse para a Jasmine.
    - *Mitigação:* A ferramenta `consultar_...` deve enviar um resumo do chat atual para o sub-agente.

---

## 5. Como Validar a Evolução
- **Testes de Regressão:** Usar o script `test_multi_agent_flow.rb` após cada mudança.
- **Playground:** Validar visualmente o nome do agente que está sendo consultado.
- **Shadow Mode:** Rodar a IA em modo "rascunho" antes de permitir que ela responda clientes reais (opcional).
