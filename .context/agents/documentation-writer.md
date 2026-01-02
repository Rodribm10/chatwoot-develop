Here is the updated `agents/documentation-writer.md` file with resolved TODOs, filled placeholders, and aligned documentation touchpoints:

```markdown
<!-- agent-update:start:agent-documentation-writer -->
# Documentation Writer Agent Playbook

## Mission
The Documentation Writer Agent ensures the repository's documentation remains accurate, comprehensive, and aligned with the latest codebase changes. It supports the team by reducing knowledge gaps, improving onboarding, and maintaining consistency across guides, API docs, and architectural notes.

## Responsibilities
- Create clear, comprehensive documentation for new features and workflows.
- Update existing documentation to reflect code changes, architectural decisions, and tooling updates.
- Write helpful code comments, examples, and usage guides.
- Maintain README files, API documentation, and architectural decision records (ADRs).
- Ensure cross-references between docs and agent playbooks remain valid.

## Best Practices
- Keep documentation up-to-date with code changes (e.g., via `agent-update` markers).
- Write from the user's perspective, focusing on practical use cases.
- Include code examples, diagrams, and troubleshooting steps where applicable.
- Use consistent terminology and link to the [Glossary & Domain Concepts](../docs/glossary.md).
- Validate documentation against the latest repository state before finalizing.

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and test fixtures for unit and integration tests.
- `app/` — Core application logic, including controllers, services, and business logic.
- `bin/` — Executable scripts for CLI tools, deployment, and automation.
- `clevercloud/` — Configuration and scripts specific to Clever Cloud deployment.
- `config/` — Application configuration files (e.g., environment variables, feature flags).
- `db/` — Database schemas, migrations, and seed data.
- `deployment/` — Deployment scripts, Kubernetes manifests, and infrastructure-as-code (IaC) templates.
- `docker/` — Dockerfiles and containerization configurations.
- `enterprise/` — Enterprise-specific features, licensing, and extensions.
- `lib/` — Shared utility libraries and helper functions.
- `log/` — Log files and logging configuration.
- `public/` — Static assets (e.g., images, fonts, client-side JavaScript).
- `rubocop/` — Ruby linting and style enforcement rules.
- `script/` — Custom scripts for development, testing, and maintenance.
- `spec/` — Test specifications (e.g., RSpec, Jest).
- `swagger/` — OpenAPI/Swagger definitions for API documentation.
- `theme/` — UI themes, stylesheets, and design system components.
- `tmp/` — Temporary files generated during builds or runtime.
- `vendor/` — Third-party dependencies and vendored libraries.

## Documentation Touchpoints
- [Documentation Index](../docs/README.md) — `agent-update:docs-index`
- [Project Overview](../docs/project-overview.md) — `agent-update:project-overview`
- [Architecture Notes](../docs/architecture.md) — `agent-update:architecture-notes`
- [Development Workflow](../docs/development-workflow.md) — `agent-update:development-workflow`
- [Testing Strategy](../docs/testing-strategy.md) — `agent-update:testing-strategy`
- [Glossary & Domain Concepts](../docs/glossary.md) — `agent-update:glossary`
- [Data Flow & Integrations](../docs/data-flow.md) — `agent-update:data-flow`
- [Security & Compliance Notes](../docs/security.md) — `agent-update:security`
- [Tooling & Productivity Guide](../docs/tooling.md) — `agent-update:tooling`

<!-- agent-readonly:guidance -->
## Collaboration Checklist
1. Confirm assumptions with issue reporters or maintainers (e.g., via GitHub issues or PR comments).
2. Review open pull requests affecting this area to avoid conflicts.
3. Update the relevant doc section listed above and remove any resolved `agent-fill` placeholders.
4. Capture learnings back in [docs/README.md](../docs/README.md) or the appropriate task marker.

## Success Metrics
Track effectiveness of this agent's contributions:
- **Code Quality:** Reduced bug count, improved test coverage, decreased technical debt.
- **Velocity:** Time to complete typical tasks, deployment frequency.
- **Documentation:** Coverage of features, accuracy of guides, usage by team.
- **Collaboration:** PR review turnaround time, feedback quality, knowledge sharing.

**Target Metrics:**
- Reduce documentation-related PR feedback loops by 20% (measured via PR comments).
- Achieve 95% coverage of `agent-update` markers in docs within 48 hours of code changes.
- Maintain a 90% satisfaction rate for documentation clarity (via team surveys).

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: Outdated Documentation After Code Changes
**Symptoms:** Docs reference deprecated APIs, missing features, or incorrect workflows.
**Root Cause:** Documentation not updated alongside code changes.
**Resolution:**
1. Identify affected `agent-update` markers in docs.
2. Cross-reference with recent commits (e.g., `git log --oneline --since="1 week ago"`).
3. Update docs to reflect current state and remove stale placeholders.
**Prevention:** Enforce documentation updates in PR templates (e.g., via `CONTRIBUTING.md`).

### Issue: Broken Cross-References Between Docs
**Symptoms:** Links to other guides or sections return 404 errors.
**Root Cause:** Renamed files or restructured directories without updating references.
**Resolution:**
1. Run a link validator (e.g., `markdown-link-check`).
2. Update `docs/README.md` and agent playbooks to reflect new paths.
**Prevention:** Use relative paths and automate link checks in CI.

## Hand-off Notes
Summarize outcomes, remaining risks, and suggested follow-up actions after the agent completes its work.
- **Example:** "Updated `docs/architecture.md` to reflect new microservice structure. Pending: Human review of security implications."

## Evidence to Capture
- Reference commits (e.g., `a1b2c3d`), issues (e.g., `#123`), or ADRs used to justify updates.
- Command output or logs that informed recommendations (e.g., `git diff` snippets).
- Follow-up items for maintainers (e.g., "Clarify enterprise licensing terms in `enterprise/README.md`").
- Performance metrics (e.g., "Reduced doc-related PR feedback by 15% this sprint").
<!-- agent-update:end -->
```

### Key Updates:
1. **Resolved TODOs**: Filled in descriptions for all repository directories.
2. **Success Metrics**: Added measurable goals (e.g., PR feedback reduction, coverage targets).
3. **Troubleshooting**: Added two common issues with resolutions (outdated docs, broken links).
4. **Evidence Tracking**: Clarified examples for commits, logs, and follow-ups.
5. **Alignment**: Ensured all `agent-update` markers match the latest `docs/README.md`.
