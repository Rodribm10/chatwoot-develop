---
name: removing-code
description: Surgically removes verified dead code (local vars, unused imports) ONLY after audit/organization and explicit user approval. Zero structural changes.
---

# Surgical Code Removal Specialist

## Mission

To eliminate verified dead code (variables, imports, local parameters) with surgical precision, reducing technical noise WITHOUT altering system behavior, breaking contracts, or refactoring logic. **We only remove what is explicitly approved.**

## When to use this skill

- ONLY AFTER running `auditing-code` AND `organizing-code`.
- When `audit_report.md` and `organization_report.md` confirm items are safe.
- To finalize a cleanup cycle.
- **Trigger phases:** `CLEANUP`, `REMOVE`, `PURGE`, `FINALIZE`.

## Regras de Ouro (INQUEBRÁVEIS)

1. **Approval First**: No removal without explicit user confirmation (per item or block).
2. **Strict Scope**: No removal outside the proposed list.
3. **No Structural Changes**: Do not move files, change folders, or alter architecture.
4. **No Public API Changes**: Public signatures are untouchable.
5. **Reversibility**: Every action must be easily reversible.

**ABORT** if any rule cannot be guaranteed.

## Workflow

Copy this checklist to `task.md`:

- [ ] **Phase 1: Input & Validation**
  - [ ] Read `audit_report.md` AND `organization_report.md`.
  - [ ] Verify items are marked `SAFE`.
  - [ ] Check if items were preserved/documented in Organization phase.
- [ ] **Phase 2: Removal Proposal**
  - [ ] Generate `cleanup_proposal.md` with approval checkboxes.
  - [ ] **STOP** and Request Approval.
- [ ] **Phase 3: Execution (Approved Only)**
  - [ ] Check Idempotency (Skip if already removed).
  - [ ] Remove _exact_ approved lines.
  - [ ] Minimal diffs (no auto-formatting).
- [ ] **Phase 4: Post-Execution & Safety**
  - [ ] Verify file syntax (compilation/parsing).
  - [ ] Ensure local references check.
  - [ ] Generate `cleanup_report.md`.

## Authorized Scope (ONLY)

Remove **ONLY** if verified unused and safe:

- **Local Variables**: Defined within a method, never read, no side effects.
- **Local Parameters**: Private methods only. NOT callbacks, overrides, or public APIs.
- **Imports**:
  - **Named Imports Only** (e.g., `import { X } from 'y'`).
  - **FORBIDDEN**: Bare imports (`import 'y'`) or side-effect imports.
  - **FORBIDDEN**: Imports initializing plugins, polyfills, CSS, or observability.

## Forbidden Scope (NEVER REMOVE)

- **Public Methods / APIs**
- **Jobs, Workers, Schedulers**
- **Webhooks & External Callbacks**
- **Controllers & Routes**
- **AI Agents / Tools**
- **Feature Flags / Dynamic Code** (`send`, `eval`)
- **Migrations**
- **Dependencies (Gems/Packages)**
- **Entire Files**

If in doubt -> **DO NOT REMOVE**.

## Instructions

### 1. Proposal Generation

Create `cleanup_proposal.md` with Governance:

```markdown
# Removal Proposal

Please mark [x] to approve specific removals.

| Approve | File      | Type      | Item           | Reason              |
| :-----: | :-------- | :-------- | :------------- | :------------------ |
|   [ ]   | `User.rb` | Local Var | `unused_count` | 0 references        |
|   [ ]   | `Util.js` | Import    | `lodash`       | Unused named import |
```

### 2. Execution Rules

- **Idempotency**: If the line/item is missing, log as "Already Removed" and continue. DO NOT fail.
- **Precision**: Remove only the target line.
- **Whitespace**: Do not reformat the rest of the file.
- **State**: If an item has `[INTENTIONAL]` or `[LEGACY]` tags, **SKIP IT**.

### 3. Verification (Post-Execution)

- **Syntax Check**: Ensure the file parses correctly (e.g., no syntax errors introduced).
- **Broken Refs**: Ensure no _other_ code in the _same file_ was referencing the removed item (sanity check).
- **No Test Suite**: Automated tests are NOT required for this specific step (assumed low risk).

## Anti-Patterns

- **"While I'm here..."**: Cleaning up unrelated code while removing a variable.
- **Speculative Removal**: "This looks unused". (Must be proven audit-safe).
- **Breaking Builds**: Removing dependencies or critical imports.
- **Refactoring**: Changing logic flow instead of just removing the dead leaf.

## Output Files

- `cleanup_proposal.md` (Proposal with approval checkboxes)
- `cleanup_report.md` (After execution summary)
