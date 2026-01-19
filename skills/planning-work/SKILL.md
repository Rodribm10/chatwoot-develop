---
name: planning-work
description: Creates comprehensive implementation plans with bite-sized tasks. Use when you have clear requirements and need a step-by-step guide for execution.
---

# Planning Work (Writing Plans)

## When to use this skill

- After requirements are clear (e.g., post-brainstorming).
- Before modifying any code for a multi-step task.
- When you need to generate a `docs/plans/YYYY-MM-DD-feature.md` file.

## Workflow

- [ ] **Analyze Context**: Understand codebase and questionable taste.
- [ ] **Create Header**: Start plan with the required header and goal.
- [ ] **Define Architecture**: Summarize approach in 2-3 sentences.
- [ ] **Break Down Tasks**: Create bite-sized (2-5 min) tasks.
- [ ] **Write Task Steps**: For each task, define files, tests, and step-by-step TDD instructions.
- [ ] **Save Plan**: Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`.
- [ ] **Confirm**: Present options for execution.

## Instructions

### 1. Plan Philosophy

- Assume the executor has **zero context**.
- **Bite-Sized:** Each task should be 2-5 minutes of work.
- **Micro-Steps:** "Write failing test" -> "Verify failure" -> "Implement minimal code" -> "Verify pass" -> "Commit".
- **DRY, YAGNI, TDD.**

### 2. Plan Header Template

Every plan MUST start with:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies/libraries]

---
```

### 3. Task Structure Template

```markdown
### Task N: [Component Name]

**Files:**

- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**
[Code Block]

**Step 2: Run test (Expect Fail)**
`command to run test`

**Step 3: Write minimal implementation**
[Code Block]

**Step 4: Run test (Expect Pass)**
`command to run test`

**Step 5: Commit**
`git commit -m "feat: ..."`
```

### 4. Execution Handoff

After saving the plan, offer:

1.  **Subagent-Driven:** You iterate task-by-task in this session.
2.  **Parallel Session:** User opens a new session/window to execute.

## Key Principles

- **Exact file paths** always.
- **Complete code snippets** (no "add validation logic", write the logic).
- **Exact commands** for running tests.
- **Reference other skills** if needed.
