---
name: architecture-review
description: Reviews project architecture, folder structure, and code organization. Suggests pragmatic improvements without requiring full rewrites.
---

# Architecture Review Specialist

## Mission

Identify structural issues and suggest incremental improvements that make the codebase easier to understand, maintain, and extend.

## When to use

- When codebase feels disorganized
- Before adding major new features
- When onboarding new developers
- Quarterly architecture health check

## Review Dimensions

### 1. Folder Structure

- Proper separation of concerns
- Consistent naming conventions
- Logical grouping of related code

### 2. Layering

- Controllers should be thin
- Business logic in Services/Interactors
- Data access in Models/Repositories
- Clear boundaries between layers

### 3. Dependencies

- No circular dependencies
- Proper use of namespaces
- External integrations isolated

### 4. Code Patterns

- Consistent use of design patterns
- No God Objects (classes doing too much)
- Proper error handling strategy

## Workflow

- [ ] **Phase 1: Structure Analysis**

  - [ ] Map current folder organization
  - [ ] Identify misplaced files
  - [ ] Check naming consistency

- [ ] **Phase 2: Responsibility Analysis**

  - [ ] Fat controllers (>50 lines)
  - [ ] Fat models (>200 lines)
  - [ ] Missing service layer
  - [ ] Business logic in views

- [ ] **Phase 3: Coupling Analysis**

  - [ ] Circular dependencies
  - [ ] High coupling between modules
  - [ ] Missing abstraction layers

- [ ] **Phase 4: Recommendations**
  - [ ] Create `architecture_improvements.md`
  - [ ] Prioritize by impact vs effort
  - [ ] Provide migration path

## Report Format

Output: `architecture_improvements.md`

```markdown
# Architecture Improvements Report

## Executive Summary

Brief overview of the codebase health and top 3 priorities.

## Priority 1: [Issue Name]

- **Issue**: Description of the structural problem.
- **Location**: `app/controllers/legacy_controller.rb`
- **Recommendation**: Exact steps to refactor.
- **Impact**: High (Critical for stability) / Medium (Tech debt) / Low (Nice to have)

## Detailed Findings

### Folder Structure

- [Observation 1]
- [Observation 2]

### Layering Violations

| Component         | Violation                            | Proposed Fix                |
| :---------------- | :----------------------------------- | :-------------------------- |
| `UsersController` | Contains 200 lines of business logic | specific service extraction |

### Dependency Issues

- [ ] Circular dependency detected between A and B.

## Roadmap

1. [Immediate Fixes]
2. [Short-term Refactoring]
3. [Long-term Restructuring]
```
