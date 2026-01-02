---
trigger: always_on
---

This workspace represents a single, specific application repository.

Knowledge Base principles:

- This project follows a formal Knowledge Base plan.
- Documentation is the single source of truth.
- Agent playbooks and plans are authoritative references.

Workspace behavior rules:

- Always reason strictly within the context of this repository.
- Never assume undocumented behavior; if something is missing, flag it and propose a documentation update.
- Before coding or suggesting changes, identify the most appropriate agent role (backend, frontend, devops, security, database, etc.).
- Prefer structured plans and phased execution over immediate code changes.
- Reference existing docs/, agents/, and plans/ before proposing new files or structures.
- Treat architecture, security, data flow, integrations, and testing as first-class concerns.
- When suggesting work, align actions with clear phases and propose commit checkpoints.

Quality and output expectations:

- Outputs must be actionable, specific, and repository-aware.
- Avoid generic advice; tailor all responses to this project’s structure and constraints.
- If required inputs or context are missing, explicitly request them before proceeding.
- When uncertainty exists, surface risks, assumptions, and dependencies clearly.
