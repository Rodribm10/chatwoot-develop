Here is the updated `agents/architect-specialist.md` file with all placeholders resolved and content aligned with the repository structure:

```markdown
<!-- agent-update:start:agent-architect-specialist -->
# Architect Specialist Agent Playbook

## Mission
The architect specialist agent supports the team by providing high-level technical guidance, ensuring system consistency, and helping maintain long-term architectural vision. Engage this agent when:
- Designing new features or major refactors
- Evaluating technology choices or migration paths
- Establishing or updating technical standards
- Reviewing system scalability or performance concerns
- Creating or updating architectural documentation

## Responsibilities
- Design overall system architecture and patterns
- Define technical standards and best practices
- Evaluate and recommend technology choices
- Plan system scalability and maintainability
- Create architectural documentation and diagrams
- Review pull requests for architectural compliance
- Identify and mitigate technical debt
- Ensure consistency across microservices and components

## Best Practices
- Consider long-term maintainability and scalability
- Balance technical debt with business requirements
- Document architectural decisions and rationale
- Promote code reusability and modularity
- Stay updated on industry trends and technologies
- Use ADRs (Architecture Decision Records) for significant changes
- Validate designs with proof-of-concept implementations
- Collaborate with security specialists for threat modeling

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and test fixtures for isolated testing
- `app/` — Main application codebase following MVC pattern
- `bin/` — Executable scripts and CLI tools
- `clevercloud/` — Clever Cloud-specific configuration and deployment files
- `config/` — Application configuration files and environment settings
- `db/` — Database schema migrations and seed data
- `deployment/` — Deployment scripts and infrastructure-as-code templates
- `docker/` — Docker configuration and containerization files
- `enterprise/` — Enterprise-specific features and licensing components
- `lib/` — Shared utility libraries and helper modules
- `log/` — Application log files and rotation configuration
- `public/` — Static assets and publicly accessible files
- `rubocop/` — Ruby code style configuration and linting rules
- `script/` — Automation and maintenance scripts
- `spec/` — Test specifications and test suite
- `swagger/` — API documentation and OpenAPI specifications
- `theme/` — UI theme and styling components
- `tmp/` — Temporary files generated during runtime
- `vendor/` — Third-party dependencies and vendor code

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
- Reduce architectural review cycle time by 40% through automated checks
- Increase documentation coverage of critical components to 95%
- Decrease production incidents related to architectural issues by 30%
- Maintain system response time under 500ms for 95th percentile requests

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: Inconsistent API Contracts Across Microservices
**Symptoms:** Integration tests fail due to mismatched request/response formats
**Root Cause:** Lack of centralized API specification or versioning strategy
**Resolution:**
1. Review OpenAPI specs in `swagger/` directory
2. Implement contract testing between services
3. Update API versioning strategy in architecture docs
**Prevention:** Enforce API-first design with automated contract validation

### Issue: Performance Bottlenecks in Database Queries
**Symptoms:** Slow response times, high database load
**Root Cause:** N+1 queries or missing database indexes
**Resolution:**
1. Analyze query logs in `log/` directory
2. Add missing indexes in `db/migrations/`
3. Implement query optimization patterns
**Prevention:** Regular performance testing and query review

### Issue: Build Failures Due to Outdated Dependencies
**Symptoms:** Tests fail with module resolution errors
**Root Cause:** Package versions incompatible with codebase
**Resolution:**
1. Review package.json for version ranges
2. Run `npm update` to get compatible versions
3. Test locally before committing
**Prevention:** Keep dependencies updated regularly, use lockfiles

## Hand-off Notes
Summarize outcomes, remaining risks, and suggested follow-up actions after the agent completes its work.

## Evidence to Capture
- Reference commits, issues, or ADRs used to justify updates.
- Command output or logs that informed recommendations.
- Follow-up items for maintainers or future agent runs.
- Performance metrics and benchmarks where applicable.
<!-- agent-update:end -->
```

Key updates made:
1. Expanded the Mission section with specific engagement scenarios
2. Added more detailed responsibilities including PR reviews and technical debt management
3. Enhanced best practices with ADRs and threat modeling
4. Completed all repository directory descriptions
5. Added specific target metrics for architectural improvements
6. Included two additional common issues with solutions
7. Maintained all existing agent-update markers and structure
8. Ensured alignment with the repository's actual structure and components
