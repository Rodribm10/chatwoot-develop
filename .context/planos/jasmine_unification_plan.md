# Plano de Unificação Jasmine & Capitão

## Objetivo

Fundir as capacidades customizadas da "Jasmine" (RAG, Detecção de Intenção, Ferramentas Específicas) na estrutura nativa do "Capitão" (IA do Chatwoot). O resultado será um assistente único e poderoso ("Capitão") que possui toda a inteligência originalmente construída para a Jasmine.

## Arquitetura

### 1. Estratégia de Modelo de Dados

**Adoção**: Transição dos modelos `Jasmine::*` para modelos `Captain::*`.

- `Jasmine::InboxConfig` -> `Captain::Assistant` (já suporta configuração)
- `Jasmine::Document` -> `Captain::Document` (suporte nativo a RAG)
- `Jasmine::UnknownIntent` -> `Captain::AssistantResponse` (para FAQs pendentes)

### 2. Integração de Lógica

**Portabilidade do BrainService**:
A lógica central do `Jasmine::BrainService` (Detecção de Intenção + Seleção de Estratégia) será integrada ao `Captain::Llm::ResponseService` (ou equivalente).

- **Detecção de Intenção**: Implementar como uma etapa no pipeline de processamento do Capitão.
- **Estratégia RAG**: Usar as capacidades existentes de `KnowledgeBase` do Capitão, mas aprimoradas com a lógica de "Playbook" da Jasmine.

### 3. Unificação de Ferramentas

**Migração de Ferramentas**:

- `Jasmine::ToolConfig` -> `Captain::CustomTool`
- Garantir que o executor de ferramentas do Capitão suporte as integrações de API específicas que a Jasmine usava (reservas de hotel, etc.).

### 4. Regras de Ouro (Cérebro Jasmine)

⚠️ **RAG do Capitão vs Jasmine**:

- A lógica RAG da Jasmine **prevalece**.
- Obrigatório uso de threshold por distância.
- Brain decide se busca RAG, não o LLM.

⚠️ **Playbook vs System Prompt**:

- No Capitão, o campo `instructions` será logicamente dividido:
  1. System Prompt (Identidade fixa)
  2. Playbook (Estratégia operacional montada pelo Brain)

⚠️ **Ferramentas Críticas**:

- Ferramentas de negócio (reservas, fotos, escalar) **NÃO** usam function calling do LLM.
- São executadas pelo Brain **antes** do LLM.

### 5. Ordem Obrigatória de Execução

1. Verificar etiqueta `desligar_ia`
2. Rodar Brain (intenção + estratégia)
3. Executar ferramenta (se houver - ToolRunner não-nativo)
4. Buscar RAG (se obrigatório pela estratégia)
5. Montar prompt (com Playbook + Contexto + Output Normalizado)
6. Chamar LLM (apenas para redação final)
7. Atualizar estado/etiquetas

## Passos de Implementação

### Fase 1: Exploração e Mapeamento (Atual)

- [x] Identificar modelos do Capitão (`Captain::Assistant`, `Captain::Document`)
- [x] Identificar serviços do Capitão (`Captain::Llm::*`, `Captain::Tools::*`)

### Fase 2: Brain Layer Implementation (Concluída)

- [x] **Schema**: Criada tabela `captain_tool_configs` (indexada por conta/inbox/tool).
- [x] **Serviços**: Criados `JasmineBrain`, `ToolRunner`, `Definitions`, `StatusParser`.
- [x] **Injeção**: `AssistantChatService` modificado para consultar o Brain antes do LLM.
- [x] **Lógica**: Implementada lógica de "Stop AI" (`desligar_ia`) e Webhooks.

### Fase 3: Integração de Ferramentas (UI)

- [ ] **Backend**: Criar API para gerenciar configurações de ferramentas (`CaptainToolConfig`).
- [ ] **Frontend**: Adicionar aba "Ferramentas" nas configurações do Assistente Capitão.
- [ ] **Frontend**: Criar formulário dinâmico que lista as ferramentas disponíveis (`DEFINITIONS`) e permite configuração por Inbox (Ativar/Desativar, URL, Credenciais).

### Fase 4: Unificação Frontend

- [ ] **Usar UI do Capitão**: Direcionar o usuário para usar a aba "Assistentes" (Capitão).
- [ ] **Ocultar Aba Jasmine**: Remover o painel customizado da Jasmine assim que a funcionalidade for equiparada.

## Ações Necessárias do Usuário

1.  **Criar um Assistente**: Usar a UI do Capitão para criar um novo Assistente.
2.  **Habilitar Ferramentas**: Configurar as ferramentas de API dentro desse Assistente.
3.  **Upload de Docs**: Re-enviar a base de conhecimento (PDF/Texto) para o Assistente Capitão.

## Benefícios

- **Interface Única**: Sem alternância entre "Jasmine" e "Capitão".
- **Recursos Nativos**: Beneficiar-se das atualizações futuras de IA do Chatwoot.
- **Manutenibilidade**: Menos código customizado para manter.
