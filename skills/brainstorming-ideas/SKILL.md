---
name: brainstorming-ideas
description: Explores user intent, requirements, and design before implementation. Use this before starting any creative work or new feature.
---

# Brainstorming Ideas Into Designs

## When to use this skill

- When starting a new feature or component.
- When requirements are vague or high-level.
- Before writing any code for complex tasks.
- To clarify user intent and design architecture.

## Workflow

- [ ] **Understand Context**: Read existing files, docs, and recent commits.
- [ ] **Iterative Questions**: Ask one question at a time to clarify requirements.
- [ ] **Explore Approaches**: Propose 2-3 different solutions with trade-offs.
- [ ] **Draft Design**: Present the design in small sections (200-300 words).
- [ ] **Validate**: Ask for confirmation after each section.
- [ ] **Finalize**: Commit the agreed design to `docs/plans/YYYY-MM-DD-<topic>-design.md`.

## Instructions

### 1. Understanding the Idea

- **Check context first:** Files, docs, recent commits.
- **Ask ONE question at a time:** Don't overwhelm.
- **Prefer multiple choice:** "Should we use A or B?" is better than "How should we do this?".
- **Focus on:** Purpose, limits, success criteria.

### 2. Exploring Approaches

- Always propose **2-3 options**.
- Explain trade-offs for each.
- State your **recommended option** clearly at the beginning.

### 3. Presenting the Design

- Break it down into **sections of 200-300 words**.
- **Pause** after each section to ask: _"Does this look right so far?"_
- Sections to cover:
  - Architecture / Component Structure
  - Data Flow
  - Error Handling
  - Testing Strategy

### 4. After the Design

- **Documentation:** Save the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`.
- **Handoff:** Ask "Ready to set up for implementation?".
- **Next Step:** Suggest using the `planning-work` skill to create the implementation plan.

## Key Principles

- **One question at a time.**
- **YAGNI ruthlessly** (Remove unnecessary features).
- **Incremental validation.**
- **Be flexible:** Clarify if typically doesn't make sense.
