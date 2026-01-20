---
name: organizing-code
description: Organizes and clarifies codebase structure after auditing. Focuses on readability, standardized comments, and non-destructive cleanup without altering behavior.
---

# Code Organization & Clarification Specialist

## Mission

To reduce confusion and cognitive load by organizing code, standardizing comments, and clarifying intent, WITHOUT deleting files, changing behavior, or breaking contracts. This skill acts as a "gardener" for the codebase, prioritizing **idempotency** and **reversibility**.

## When to use this skill

- AFTER running the `auditing-code` skill.
- When the codebase feels cluttered or ambiguous.
- To prepare legacy code for future refactoring or AI analysis.
- **Trigger phases:** `ORGANIZE`, `CLARIFY`, `DOCUMENT`, `TIDY`.

## Workflow

Copy this checklist to `task.md`:

- [ ] **Phase 1: Input Analysis**
  - [ ] Read `audit_report.md` (if available).
  - [ ] Identify areas marked as "CAUTION" or "KEEP".
- [ ] **Phase 2: Check Idempotency (Content-Based)**
  - [ ] Verify if files already meet the organization standards.
  - [ ] Skip files that already have sorted imports or standard headers.
  - [ ] **Rule**: Logic must be deterministic based on FILE CONTENT, ignoring git history.
- [ ] **Phase 3: Safe Cleanup (Non-Destructive)**
  - [ ] Remove unused _local_ variables (verified SAFE).
  - [ ] Organize imports (sort, group, remove dups - **strict side-effect check**).
  - [ ] Standardize comments.
- [ ] **Phase 4: Clarification & Documentation**
  - [ ] Add standard tags (`[INTENTIONAL]`, `[LEGACY]`).
  - [ ] Document implicit dependencies (Gemfile or docs).
- [ ] **Phase 5: Reporting**
  - [ ] Generate `organization_report.md`.

## Instructions

### 1. Idempotency Rules (Crucial)

Before applying any change, check if it's needed based on **FILE CONTENT**:

- **Comments**: Do NOT add `[INTENTIONAL]` if the line already has it.
- **Imports**: Check if imports are already sorted. If yes, skip.
- **Logic**: If the code is already clear, DO NOT touch it.

### 2. Actions & Safety

#### Imports & Formatting

- **Global Formatting**: **PROHIBITED**. Do not run Prettier/ESLint on the whole file.
- **Local Adjustments**: Minimal whitespace changes are allowed **ONLY** within the organized lines (e.g., grouping imports).
- **Justification**: Any formatting tweak must be explicitly logged in the organization report.

#### Dependencies

- **Ruby (Gemfile)**: Use `#` comments for legacy/audit notes.
- **JS (package.json)**: **NO COMMENTS** inside JSON (strict format).
  - Action: Create or update `docs/dependency_notes.md`.
  - Content: Reference the package name, version, and reason for the note.

#### Structural Integrity (Strict No-Touch)

- **NO** moving files between folders.
- **NO** rearranging domain boundaries.
- **NO** altering namespaces or explicit exports.

### 3. Placeholder Strategy

For code that appears unused but is blocked from deletion:

**DO NOT DELETE.** Instead, wrap or annotate:

```ruby
# [INTENTIONAL] Reserved for future feature expansion (Phase 2)
def future_method
  # ...
end
```

Standard Tags:

- `[INTENTIONAL]` - Kept on purpose.
- `[LEGACY]` - Old behavior, do not touch.
- `[FUTURE]` - Planned features.

### 4. Report Format

Output to `organization_report.md` with explicit reasoning. Ensure columns are consistent.

```markdown
# Organization Report: [Scope]

## Changes Applied

| File         | Change             | Reason              | Risk | Scope       |
| :----------- | :----------------- | :------------------ | :--- | :---------- |
| `User.rb`    | Sorted imports     | Readability         | Low  | Local       |
| `Billing.rb` | Added [LEGACY] tag | Identified in Audit | None | Methodology |

## Skipped / Preserved

| File           | Item        | Reason                         | Risk   | Scope       |
| :------------- | :---------- | :----------------------------- | :----- | :---------- |
| `Init.js`      | Import Sort | Potential side-effect import   | Medium | Integration |
| `package.json` | Comments    | JSON does not support comments | Low    | Config      |

## Structural Suggestions (For Future)

- Consider moving `Admin` module to its own namespace (documented only).
```

## Anti-Patterns

- **Moving code** "to look prettier" or aesthetic reordering.
- **Touching entrypoints** (Jobs, Webhooks, AI Agents).
- **Redundant tagging** (Adding `[INTENTIONAL]` twice).
- **Global Reformatting** (Changing whitespace outside of target lines).
