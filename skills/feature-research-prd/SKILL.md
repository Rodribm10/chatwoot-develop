---
name: researching-feature-prd
description: Prepares a PRD by researching the codebase and external docs. Use when the user mentions PLAN, RESEARCH_FEATURE, or PREPARE_PRD.
---

# Feature Research & PRD Specialist

## When to use this skill

- User requests creating/modifying a feature and wants a PRD first.
- Trigger keywords: PLAN, RESEARCH_FEATURE, PREPARE_PRD.

## Workflow

Copy this checklist to `task.md`:

- [ ] **Fase 1: Descoberta Interna (Codebase)**
  - [ ] Identificar arquivos que precisarão ser modificados (`find_by_name`).
  - [ ] Identificar padrões internos existentes para reutilização (evitar duplicidade de componentes/funções).
- [ ] **Fase 2: Descoberta Externa (Web)**
  - [ ] Buscar documentação oficial atualizada das tecnologias envolvidas (ex: "NextAuth v5 docs").
  - [ ] Buscar "Implementation Patterns" recomendados para o problema.
- [ ] **Fase 3: Síntese (Geração do PRD)**
  - [ ] Filtrar o excesso de informação (manter apenas o relevante para a implementação).
  - [ ] Criar/Sobrescrever o arquivo: `PRD.md`.

## Instructions

- Priorize fontes oficiais e atuais para documentação externa.
- Use `rg` para localizar padrões internos e evitar duplicidade.
- Registre apenas o essencial para implementação (sem overengineering).
- Evite suposições; confirme com evidências do código/dos docs.

## PRD Template

```markdown
# Product Requirements Document (PRD)
**Feature**: {{USER_QUERY}}
**Data**: {{CURRENT_DATE}}

## 1. Contexto & Objetivo
Breve descrição do que vamos construir.

## 2. Contexto da Base de Código (Interno)
- **Arquivos para Modificar**:
  - `caminho/do/arquivo.ts`: Motivo da alteração.
- **Padrões para Reutilizar**:
  - Ex: Usar o componente `Button.tsx` existente.
  - Ex: Usar a função de log em `lib/logger.ts`.

## 3. Documentação & Padrões (Externo)
- **Links/Snippets de Docs**:
  - Trecho da documentação oficial explicando o método a ser usado.
- **Padrão de Implementação**:
  - Resumo de como resolveremos isso (ex: "Usar Webhooks ao invés de Polling").

## 4. Restrições Técnicas
- Listar limitações (ex: versão do Node, estrutura de pastas).
```
