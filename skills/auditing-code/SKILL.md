---
name: auditing-code
description: Audits the project to identify unused code while strictly protecting entrypoints, integrations, and dynamic calls. Generates evidence-based risk reports and reversible cleanup plans.
---

# Code Audit & Cleanup Specialist

## Mission

To reduce technical debt and cognitive load for both humans and AI agents by identifying unused code, WITHOUT altering the system's behavior or risking stability. We prioritize safety, reversibility, and explicit evidence over aggressive cleanup.

## When to use this skill

- When the user requests a code audit, cleanup, or identification of "dead code".
- When evaluating legacy modules for refactoring.
- **Trigger phases:** `AUDIT` (Mapping), `ASSESS` (Risk Classification), `REPORT` (Evidence), `PLAN` (Cleanup Strategy).

## Workflow

Copy this checklist to `task.md`:

- [ ] **Phase 1: Protection & Mapping**
  - [ ] Identify **Critical Entrypoints** (Routes, Jobs, Webhooks, CLI, AI Agents).
  - [ ] Map potentially unused items (using `grep`, `find`, LSP).
- [ ] **Phase 2: Risk Assessment & Evidence**
  - [ ] Classify strictly: **SAFE**, **CAUTION**, or **KEEP**.
  - [ ] Collect usage evidence for every item (or lack thereof).
  - [ ] Validate against "Dynamic Use" exclusions (Reflection, strings).
- [ ] **Phase 3: Reporting**
  - [ ] Generate `audit_report.md` (Human/AI readable).
  - [ ] Provide summary metrics.
- [ ] **Phase 4: Cleanup Strategy**
  - [ ] Create `cleanup_plan.md` (Strategy: Deprecate -> Observe -> Remove).
  - [ ] **WAIT** for explicit user approval.

## Instructions

### 1. Protection Rules (The "Red Lines")

**NEVER** classify as `SAFE` if the item matches these criteria. Must be `KEEP` or `CAUTION`.

| Category       | Protection Rule                        | Trigger Pattern Examples                         |
| :------------- | :------------------------------------- | :----------------------------------------------- |
| **Routes/API** | Public controllers, API endpoints.     | `routes.rb`, `*Controller`, `API::*`             |
| **Async Jobs** | Background workers, schedulers.        | `Sidekiq::Worker`, `ApplicationJob`, `cron.yaml` |
| **Webhooks**   | External callbacks, event handlers.    | `handle_webhook`, `on_*`, `stripe_event`         |
| **CLI/Tasks**  | Rake tasks, scripts, console commands. | `lib/tasks/*.rake`, `bin/*`                      |
| **Dynamic**    | Feature flags, ENV-driven logic.       | `ENV['FEATURE_*']`, `Features.enabled?`          |
| **Meta-Prog**  | Reflection/String-based calls.         | `send(params[:method])`, `constantize`           |
| **AI Agents**  | Tools/Skills used by Agents.           | `class *Tool`, `scenarios/*.yaml`                |

### 2. Risk Classification Logic

Every item must be tagged with a risk level.

- **✅ SAFE**:

  - Strictly internal (private methods, local vars).
  - 0 references found in entire codebase (grep check).
  - Not an entrypoint or potential meta-programming target.
  - _Constraint_: Must verify removal doesn't break syntax.

- **⚠️ CAUTION**:

  - Public methods with no _explicit_ callers.
  - Constants/Classes that "look" like headers or strict types.
  - CSS classes (could be constructed strings).
  - _Requirement_: Needs implicit usage check.

- **❌ KEEP**:
  - Valid references found.
  - Any item executing external I/O or integrations.
  - Test helpers (crucial for verifying correctness).
  - Core configuration.

### 3. Evidence Requirement

The skill **MUST** prove why an item is unused.

- **BAD**: "Variable `x` looks unused."
- **GOOD**: "Variable `x` defined at line 10. `grep -r 'x' .` returned only the definition. Local scope confirmed."

### 4. Reporting Format

Output to `audit_report.md`.

```markdown
# Audit Report: [Scope Name]

## Executive Summary

- **Total Scanned**: 50 items
- **✅ Safe to Remove**: 5
- **⚠️ Caution**: 2
- **❌ Keep**: 43

## Detailed Findings

| File/Context          | Item Type | Name/Snippet  | Risk       | Evidence/Rationale                                              |
| :-------------------- | :-------- | :------------ | :--------- | :-------------------------------------------------------------- |
| `app/models/user.rb`  | Method    | `legacy_auth` | ✅ SAFE    | Defined but never called. Grep returned 0 hits. Not a callback. |
| `app/views/home.html` | CSS Class | `.old-banner` | ⚠️ CAUTION | No static usage, but class name might be dynamic in JS.         |
| `app/jobs/mail.rb`    | Class     | `DailyMail`   | ❌ KEEP    | Inherits ApplicationJob. Likely called via Redis/Sidekiq.       |

## Recommendations

- [ ] Safe items can be removed immediately.
- [ ] Caution items should be commented out or logged first.
```

### 5. Cleanup Strategy (Incremental)

**NEVER** delete code in the audit phase. Propose a plan in `cleanup_plan.md`:

1.  **Level 1 (Safe)**: Delete dead private methods, unused local variables.
2.  **Level 2 (Deprecate)**: Add `ActiveSupport::Deprecation` warning or log "Unused code reached" for CAUTION items.
3.  **Level 3 (Observe)**: Monitor logs for 1 week.
4.  **Level 4 (Remove)**: Delete after established silence.
5.  **Level 5 (Commit & Monitor)**:
    - Commit changes with reversible message: `git commit -m "refactor: remove unused [item] - reversible"`
    - Monitor production logs for 48h
    - Keep rollback plan ready: `git revert HEAD`

## Anti-Patterns

- **Deleting files** without a rollback plan.
- **Trusting `grep` blindly** on short strings (too many collisions) or huge projects (dynamic imports).
- Removing **Database Migrations** (historic record).
- Removing **Tests** just because they verify "unused" code (the test proves the code exists, not that it's useful).

## Validation Checklist

Before proposing removal of any item, verify:

- [ ] Item is NOT in routes.rb or called by external systems
- [ ] Item is NOT inherited from framework base classes (ApplicationJob, ApplicationController)
- [ ] Item is NOT used in string interpolation or send() calls
- [ ] Item is NOT a callback (before*\*, after*_, around\__)
- [ ] Item is NOT accessed via ENV variables or feature flags
- [ ] Removal does NOT break tests (run test suite after each deletion)

## Output Files

This skill generates:

- `audit_report.md` - Evidence-based findings
- `cleanup_plan.md` - Phased removal strategy (only after user approval)
- `rollback_plan.md` - Emergency recovery steps

Never execute deletions without explicit user confirmation.
