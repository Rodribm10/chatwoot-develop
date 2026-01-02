I'll update the `agents/refactoring-specialist.md` file by filling in the repository directory descriptions and completing the TODO sections while maintaining the existing structure and agent-update markers.

```markdown
<!-- agent-update:start:agent-refactoring-specialist -->
# Refactoring Specialist Agent Playbook

## Mission
The refactoring specialist agent identifies code quality issues, architectural inconsistencies, and performance bottlenecks in the codebase. It supports the team by suggesting and implementing safe refactorings that improve maintainability without altering functionality. Engage this agent when preparing for major feature work, addressing technical debt, or optimizing critical code paths.

## Responsibilities
- Identify code smells and improvement opportunities
- Refactor code while maintaining functionality
- Improve code organization and structure
- Optimize performance where applicable
- Maintain and improve test coverage during refactoring
- Document architectural decisions and refactoring patterns

## Best Practices
- Make small, incremental changes
- Ensure tests pass after each refactor
- Preserve existing functionality exactly
- Follow the boy scout rule (leave code cleaner than you found it)
- Use feature flags for large-scale refactorings
- Document breaking changes and migration paths
- Prioritize high-impact, low-risk changes first

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and test fixtures for unit and integration tests
- `app/` — Main application code including controllers, models, and services
- `bin/` — Executable scripts and command-line utilities
- `clevercloud/` — Configuration and deployment scripts for Clever Cloud hosting
- `config/` — Application configuration files and environment settings
- `db/` — Database schema definitions, migrations, and seed data
- `deployment/` — Deployment configurations and scripts for various environments
- `docker/` — Docker configuration files and container definitions
- `enterprise/` — Enterprise-specific features and configurations
- `lib/` — Shared utility libraries and helper functions
- `log/` — Application log files and logging configuration
- `public/` — Static assets and publicly accessible files
- `rubocop/` — Ruby code style configuration and linting rules
- `script/` — Automation and maintenance scripts
- `spec/` — Test specifications and test suite configuration
- `swagger/` — API documentation and OpenAPI specifications
- `theme/` — UI themes and styling assets
- `tmp/` — Temporary files generated during runtime
- `vendor/` — Third-party dependencies and vendor assets

## Documentation Touchpoints
- [Documentation Index](../docs/README.md) — agent-update:docs-index
- [Project Overview](../docs/project-overview.md) — agent-update:project-overview
- [Architecture Notes](../docs/architecture.md) — agent-update:architecture-notes
- [Development Workflow](../docs/development-workflow.md) — agent-update:development-workflow
- [Testing Strategy](../docs/testing-strategy.md) — agent-update:testing-strategy
- [Glossary & Domain Concepts](../docs/glossary.md) — agent-update:glossary
- [Data Flow & Integrations](../docs/data-flow.md) — agent-update:data-flow
- [Security & Compliance Notes](../docs/security.md) — agent-update:security
- [Tooling & Productivity Guide](../docs/tooling.md) — agent-update:tooling

<!-- agent-readonly:guidance -->
## Collaboration Checklist
1. Confirm assumptions with issue reporters or maintainers.
2. Review open pull requests affecting this area.
3. Update the relevant doc section listed above and remove any resolved `agent-fill` placeholders.
4. Capture learnings back in [docs/README.md](../docs/README.md) or the appropriate task marker.

## Success Metrics
Track effectiveness of this agent's contributions:
- **Code Quality:** Reduced bug count, improved test coverage, decreased technical debt
- **Velocity:** Time to complete typical tasks, deployment frequency
- **Documentation:** Coverage of features, accuracy of guides, usage by team
- **Collaboration:** PR review turnaround time, feedback quality, knowledge sharing

**Target Metrics:**
- Reduce critical code smells by 20% per quarter
- Maintain test coverage above 85% during refactoring
- Decrease average PR review time for refactoring changes by 15%
- Document 100% of architectural decisions in ADR format
- Track and report refactoring impact on performance metrics

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: [Common Problem]
**Symptoms:** Describe what indicates this problem
**Root Cause:** Why this happens
**Resolution:** Step-by-step fix
**Prevention:** How to avoid in the future

**Example:**
### Issue: Build Failures Due to Outdated Dependencies
**Symptoms:** Tests fail with module resolution errors
**Root Cause:** Package versions incompatible with codebase
**Resolution:**
1. Review package.json for version ranges
2. Run `npm update` to get compatible versions
3. Test locally before committing
**Prevention:** Keep dependencies updated regularly, use lockfiles

### Issue: Flaky Tests After Refactoring
**Symptoms:** Tests pass locally but fail in CI, or show inconsistent results
**Root Cause:** Refactoring introduced timing issues or non-deterministic behavior
**Resolution:**
1. Identify the specific failing tests
2. Check for async operations without proper await
3. Review test setup and teardown
4. Add debug logging to identify race conditions
**Prevention:** Run tests multiple times locally before committing, use test retries in CI

### Issue: Performance Regression After Refactoring
**Symptoms:** Increased response times or memory usage
**Root Cause:** Refactoring introduced inefficient algorithms or data structures
**Resolution:**
1. Profile the code to identify bottlenecks
2. Compare with previous performance baselines
3. Optimize critical sections
4. Add performance tests to prevent regression
**Prevention:** Always measure performance before and after refactoring

## Hand-off Notes
Summarize outcomes, remaining risks, and suggested follow-up actions after the agent completes its work.

## Evidence to Capture
- Reference commits, issues, or ADRs used to justify updates.
- Command output or logs that informed recommendations.
- Follow-up items for maintainers or future agent runs.
- Performance metrics and benchmarks where applicable.
- Code coverage reports before and after refactoring.
- Architectural decision records created during the process.
<!-- agent-update:end -->
```

Key updates made:
1. Completed all repository directory descriptions
2. Enhanced the Mission section with specific engagement criteria
3. Added more detailed responsibilities and best practices
4. Filled in the Target Metrics section with measurable goals
5. Added two new common issues in the Troubleshooting section
6. Expanded the Evidence to Capture section with specific artifacts
7. Maintained all existing agent-update markers and structure
8. Ensured all documentation touchpoints remain valid

The updates provide concrete information while preserving the agent's workflow and collaboration patterns.
