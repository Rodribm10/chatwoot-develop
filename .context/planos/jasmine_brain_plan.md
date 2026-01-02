# Plano Técnico Evolutivo: Cérebro da Jasmine (SDR Agent)

**Versão:** 1.1 (Revisada)  
**Data:** 2025-12-27  
**Status:** Aprovado para Implementação

---

## Contexto Atual (Já Implementado)

| Componente                       | Status | Descrição                                                 |
| -------------------------------- | ------ | --------------------------------------------------------- |
| `Jasmine::Collection`            | ✅     | Coleções com visibilidade (private/shared)                |
| `Jasmine::Document`              | ✅     | Documentos com status (pending/processing/indexed/failed) |
| `Jasmine::DocumentChunk`         | ✅     | Chunks com embeddings vetoriais (pgvector)                |
| `Jasmine::EmbeddingService`      | ✅     | Chunking + OpenAI embeddings                              |
| `Jasmine::SemanticSearchService` | ✅     | Busca vetorial com **cosine distance** (`<=>`)            |
| `Jasmine::InboxConfig`           | ✅     | Configurações por inbox                                   |
| UI Dashboard                     | ✅     | Gestão de coleções e documentos                           |

> **Importante:** O backend usa **cosine distance** (quanto menor, mais similar). Threshold padrão = 0.35.

---

## 1️⃣ Arquitetura do Cérebro da Jasmine

### Diagrama de Camadas

```
┌─────────────────────────────────────────────────────────────────┐
│                    MENSAGEM DO CLIENTE                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Jasmine::BrainService                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ IntentDetector    → Detectar intenção (customizável)      │  │
│  │ StrategyDecider   → Decidir: Direto | RAG | (Tool)        │  │
│  │ PromptAssembler   → Montar contexto final                 │  │
│  │ StateUpdater      → Atualizar estado do lead              │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
   ┌─────────────┐   ┌─────────────────┐   ┌─────────────┐
   │   SYSTEM    │   │   PLAYBOOK      │   │   ESTADO    │
   │   PROMPT    │   │   SDR           │   │   DO LEAD   │
   │  (fixo,     │   │  (editável      │   │  (memória   │
   │   curto)    │   │   por inbox)    │   │   curta)    │
   └─────────────┘   └─────────────────┘   └─────────────┘
                              │
                              ▼ (OBRIGATÓRIO para preços/políticas)
                    ┌─────────────────┐
                    │  BASE VETORIAL  │
                    │     (RAG)       │
                    │  Preços, FAQs,  │
                    │  Políticas...   │
                    └─────────────────┘
```

### O que entra em cada camada

| Camada             | Conteúdo                         | Tamanho     | Frequência  |
| ------------------ | -------------------------------- | ----------- | ----------- |
| **System Prompt**  | Identidade, tom, regras          | ~500 tokens | Raro        |
| **Playbook SDR**   | Script de vendas                 | ~800 tokens | Ocasional   |
| **Estado do Lead** | Nome, etapa, qualificação        | ~200 tokens | Cada msg    |
| **Histórico**      | **Últimas 2-3 mensagens apenas** | ~300 tokens | Cada msg    |
| **RAG**            | Preços, políticas, FAQs          | Ilimitado   | Condicional |

### Regra de Ouro: Fonte da Verdade

> ⚠️ **REGRA CRÍTICA:**
>
> Se houver contexto RAG válido (abaixo do threshold de distance), a resposta **DEVE** se basear **exclusivamente** nesse conteúdo.
>
> É **PROIBIDO** complementar com conhecimento externo do modelo para:
>
> - Preços
> - Políticas
> - Regras operacionais
> - Horários
> - Disponibilidade

---

## 2️⃣ Modelagem Mínima Necessária

### Alterações em `jasmine_inbox_configs`

```ruby
# Campos existentes (manter)
:enabled             # boolean
:settings            # jsonb

# Novos campos (adicionar)
:system_prompt           # text - Prompt base
:playbook_prompt         # text - Script SDR editável
:rag_distance_threshold  # float, default 0.35 - Distance máxima (menor = mais similar)
:rag_max_results         # integer, default 3
:model                   # string, default 'gpt-4o-mini'
:temperature             # float, default 0.7
:intent_keywords         # jsonb - Dicionário de intenções customizado por inbox
```

### Estado do Lead/Conversa

Usar `conversation.custom_attributes['jasmine_state']`:

```ruby
{
  "stage": "qualification",
  "qualified": false,
  "collected_info": {
    "name": "João",
    "company": "Acme"
  },
  "rag_queries_count": 2,
  "last_intent": "price_question",
  "updated_at": "2025-12-27T10:00:00Z"
}
```

**Limites e Limpeza:**

- Tamanho máximo: 4KB
- Limpar ao fechar conversa (resolved/pending)
- Se `rag_queries_count > 5` na mesma conversa: mudar estratégia

---

## 3️⃣ Serviço Central: `Jasmine::BrainService`

### Componentes Lógicos (mesmo arquivo no V1)

```ruby
class Jasmine::BrainService
  # Componente 1: Detectar intenção
  class IntentDetector
    # Usa dicionário customizado por inbox
  end

  # Componente 2: Decidir estratégia
  class StrategyDecider
    # RAG obrigatório vs opcional
  end

  # Componente 3: Montar prompt
  class PromptAssembler
    # Limite de histórico: 2-3 mensagens
  end

  # Componente 4: Atualizar estado
  class StateUpdater
    # Limite de tamanho: 4KB
  end
end
```

### Fluxo Passo a Passo

```
1. CARREGAR CONFIGURAÇÕES
   └─ inbox.jasmine_config

2. CARREGAR ESTADO DO LEAD
   └─ conversation.custom_attributes['jasmine_state']

3. DETECTAR INTENÇÃO (IntentDetector)
   │
   │  Usa dicionário customizado por inbox:
   │  {
   │    "price_question": ["preço", "valor", "quanto custa", "quanto fica",
   │                       "tabela", "promoção", "pernoite"],
   │    "info_request": ["como funciona", "detalhe", "explica", "suíte"],
   │    "policy": ["horário", "check-in", "política", "regra"],
   │    "greeting": ["oi", "olá", "bom dia"],
   │    "objection": ["caro", "não sei", "preciso pensar"]
   │  }
   │
   └─ Retorna: intent_type + confidence

4. DECIDIR ESTRATÉGIA (StrategyDecider)
   │
   ├─ RAG OBRIGATÓRIO quando:
   │     • intenção = price_question
   │     • intenção = info_request
   │     • intenção = policy
   │     (Mesmo que LLM "ache que sabe")
   │
   ├─ RAG OPCIONAL:
   │     • intenção = objection (buscar argumentos)
   │     • intenção = general
   │
   └─ SEM RAG:
         • intenção = greeting
         • confirmações simples ("ok", "entendi")

5. BUSCAR RAG (se necessário)
   │
   │  SemanticSearchService.search(
   │    query: message.content,
   │    inbox: inbox,
   │    limit: rag_max_results,
   │    threshold: rag_distance_threshold  # Cosine distance!
   │  )
   │
   └─ Se rag_queries_count > 5:
        mudar para "Vou confirmar com a equipe"

6. MONTAR PROMPT (PromptAssembler)
   │
   │  [System Prompt]
   │
   │  [Playbook SDR]
   │
   │  [Estado do Lead]
   │
   │  [Contexto RAG] ← SE PRESENTE, É FONTE DA VERDADE
   │  "Use APENAS estas informações para responder..."
   │
   │  [Histórico: ÚLTIMAS 2-3 MENSAGENS APENAS]
   │
   │  [Mensagem Atual]
   │

7. CHAMAR LLM
   └─ RubyLLM.chat(prompt, model: config.model)

8. ATUALIZAR ESTADO (StateUpdater)
   │
   │  - Incrementar rag_queries_count
   │  - Salvar nova etapa
   │  - Verificar limite de 4KB
   │
   └─ Se conversation fechada: limpar estado

9. RETORNAR RESPOSTA
```

---

## 4️⃣ Regras de Uso da Base Vetorial (RAG)

### RAG OBRIGATÓRIO

| Intenção         | Motivo                      |
| ---------------- | --------------------------- |
| `price_question` | Evitar alucinação de preços |
| `info_request`   | Dados factuais do produto   |
| `policy`         | Regras operacionais         |

### RAG PROIBIDO

| Situação                      | Motivo           |
| ----------------------------- | ---------------- |
| Saudação ("oi", "olá")        | Desperdiça busca |
| Confirmação ("ok", "entendi") | Não há pergunta  |

### Tratamento de Resultados

```
SE distance > threshold (resultado fraco):
   └─ IGNORAR resultado
   └─ Responder: "Vou verificar isso com a equipe e já retorno."

SE nenhum resultado:
   └─ Mesma resposta de "resultado fraco"

SE múltiplos resultados válidos:
   └─ Concatenar top N
   └─ LLM sintetiza (mas não inventa)

SE resultado válido (distance ≤ threshold):
   └─ Incluir no contexto como FONTE DA VERDADE
   └─ LLM responde APENAS com base nesse conteúdo
```

### Proteção contra Loops

```
SE rag_queries_count > 5 na mesma conversa:
   └─ Parar de buscar RAG
   └─ Responder: "Deixa eu confirmar esses detalhes com a equipe."
   └─ (Opcional) Escalar para humano
```

---

## 5️⃣ Playbook SDR (Conceito)

O **Playbook** é texto curto (~500-800 palavras) que define o script de vendas.

### Estrutura

```markdown
## Objetivo

Qualificar leads e agendar visita/reserva.

## Etapas

1. ABERTURA: Cumprimentar, perguntar nome
2. DESCOBERTA: Entender necessidade
3. QUALIFICAÇÃO: Data, horário, preferências
4. APRESENTAÇÃO: Mostrar opções relevantes
5. OBJEÇÕES: Tratar dúvidas
6. FECHAMENTO: Confirmar reserva

## Perguntas Obrigatórias

- Qual seu nome?
- Para quando seria?
- Quantas pessoas?
- Prefere período diurno ou noturno?

## Objeções Comuns

- "Está caro" → Mostrar valor/diferencial
- "Preciso pensar" → Oferecer info adicional

## Regras

- NUNCA inventar preços
- SEMPRE usar preços da base de conhecimento
- Se não souber, perguntar à equipe
```

---

## 6️⃣ Preparação para Ferramentas (Plano Futuro)

> ⚠️ **NÃO implementar agora. Apenas preparar arquitetura.**

### Regra de Precedência

```
Tools críticas SEMPRE têm precedência sobre resposta livre.

Exemplo: Se existe tool "verificar_disponibilidade":
  1. BrainService detecta intenção = availability_check
  2. ANTES de chamar LLM, executa tool
  3. Resultado da tool entra no contexto
  4. LLM formula resposta com dado real
```

### Arquitetura Preparada

O `StrategyDecider` já deve prever:

```ruby
def decide
  case intent
  when :availability_check
    :execute_tool  # ← FUTURO
  when :price_question
    :rag_required
  when :greeting
    :direct_response
  end
end
```

---

## 7️⃣ Critérios de Aceite

| #   | Critério                                   | Prioridade  |
| --- | ------------------------------------------ | ----------- |
| 1   | System prompt ≤ 500 tokens                 | Alta        |
| 2   | Playbook editável por inbox                | Alta        |
| 3   | RAG obrigatório para preços/políticas      | **Crítico** |
| 4   | Threshold em **distance** (não similarity) | Alta        |
| 5   | Histórico limitado a 2-3 mensagens         | Alta        |
| 6   | Estado do lead ≤ 4KB, limpar ao fechar     | Média       |
| 7   | Proteção contra loops (rag_queries > 5)    | Média       |
| 8   | Intenções customizáveis por inbox          | Média       |
| 9   | Fonte da verdade: RAG prevalece sobre LLM  | **Crítico** |
| 10  | Arquitetura não bloqueia tools futuras     | Média       |

---

## Próximos Passos (Após Aprovação)

1. **Migration:** Adicionar campos em `jasmine_inbox_configs`
2. **Service:** Criar `Jasmine::BrainService` com componentes separados
3. **Intent Keywords:** Seed inicial de keywords por tipo de negócio
4. **UI:** Campos para System Prompt, Playbook, Threshold
5. **Hook:** Integrar com incoming messages
6. **Testes:** Specs para cada decisão

---

## Changelog

| Versão | Data       | Mudanças                                                                                                                                                    |
| ------ | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0    | 2025-12-27 | Versão inicial                                                                                                                                              |
| 1.1    | 2025-12-27 | Ajustes: distance threshold, componentes separados, dicionário customizável, RAG obrigatório, fonte da verdade, limites de histórico/estado, proteção loops |

**Status: APROVADO PARA IMPLEMENTAÇÃO** ✅
