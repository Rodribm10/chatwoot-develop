Here is the updated `agents/database-specialist.md` file with resolved TODOs, filled placeholders, and aligned documentation touchpoints:

```markdown
<!-- agent-update:start:agent-database-specialist -->
# Database Specialist Agent Playbook

## Mission
The Database Specialist Agent ensures the reliability, performance, and scalability of the project's database layer. It assists with schema design, query optimization, migration planning, and data integrity. Engage this agent when:
- Designing new database schemas or modifying existing ones
- Troubleshooting performance bottlenecks or slow queries
- Planning data migrations or rollback strategies
- Implementing backup, recovery, or compliance requirements

## Responsibilities
- Design and optimize database schemas for performance and maintainability
- Create and manage database migrations with rollback capabilities
- Optimize query performance through indexing, caching, and query restructuring
- Ensure data integrity and consistency across transactions
- Implement backup, recovery, and disaster recovery strategies
- Monitor database health and proactively address issues
- Document schema changes and their impact on business logic

## Best Practices
- **Benchmarking:** Always benchmark queries before and after optimization using realistic datasets
- **Migrations:** Plan migrations with rollback strategies and test in staging environments
- **Indexing:** Use appropriate indexing strategies (e.g., B-tree, GIN) based on workload patterns
- **Transactions:** Maintain data consistency with proper transaction isolation levels
- **Documentation:** Document schema changes, their business impact, and migration steps
- **Security:** Apply principle of least privilege and encrypt sensitive data at rest and in transit
- **Monitoring:** Set up alerts for abnormal query patterns, lock contention, or resource saturation

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and test fixtures for database testing
- `app/` — Application source code, including database interaction layers
- `bin/` — Executable scripts, including database management utilities
- `clevercloud/` — Clever Cloud-specific configuration and deployment scripts
- `config/` — Configuration files, including database connection settings
- `db/` — Database schema definitions, migrations, and seed data
- `deployment/` — Deployment scripts and database provisioning templates
- `docker/` — Docker configurations for database containers (e.g., PostgreSQL, Redis)
- `enterprise/` — Enterprise-specific database extensions or plugins
- `lib/` — Shared libraries, including database helper modules
- `log/` — Log files and rotation configurations for database auditing
- `public/` — Static assets and client-side database interaction endpoints
- `rubocop/` — Ruby style guidelines affecting database-related code
- `script/` — Utility scripts for database maintenance and reporting
- `spec/` — Test specifications, including database integration tests
- `swagger/` — API documentation referencing database-backed endpoints
- `theme/` — UI themes that may interact with database-driven content
- `tmp/` — Temporary files, including database export/import intermediates
- `vendor/` — Third-party dependencies, including database drivers

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
1. Confirm assumptions with issue reporters or maintainers before implementing changes.
2. Review open pull requests affecting database schemas, migrations, or performance.
3. Update the relevant documentation sections listed above and remove resolved `agent-fill` placeholders.
4. Capture learnings in [docs/README.md](../docs/README.md) or the appropriate task marker.

## Success Metrics
Track effectiveness of this agent's contributions:
- **Code Quality:** Reduced query-related bugs, improved test coverage for database operations, decreased technical debt in schema design
- **Velocity:** Time to complete schema migrations, query optimization tasks, and deployment frequency
- **Documentation:** Coverage of database features, accuracy of schema documentation, and usage by the team
- **Collaboration:** PR review turnaround time for database changes, feedback quality on schema designs, and knowledge sharing

**Target Metrics:**
- Reduce query execution time for top 10 slowest queries by 40% within 3 months
- Achieve 100% test coverage for all database migrations and rollback procedures
- Decrease database-related production incidents by 50% through proactive monitoring
- Document all schema changes with business impact analysis before implementation

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: Slow Query Performance
**Symptoms:** High query execution times, increased CPU usage, or timeouts
**Root Cause:** Missing indexes, inefficient joins, or unoptimized queries
**Resolution:**
1. Identify slow queries using `EXPLAIN ANALYZE`
2. Add appropriate indexes or restructure queries
3. Consider query caching for frequent reads
4. Test changes in staging with production-like data
**Prevention:** Regularly review query performance and implement indexing strategies early

### Issue: Migration Failures in Production
**Symptoms:** Deployment failures, data inconsistencies, or rollback errors
**Root Cause:** Untested migrations, missing rollback steps, or schema conflicts
**Resolution:**
1. Test migrations in a staging environment with production data
2. Ensure all migrations have corresponding rollback procedures
3. Use transactional migrations where possible
4. Monitor migration progress and validate data integrity post-migration
**Prevention:** Implement a migration testing pipeline and document all schema changes

### Issue: Data Integrity Violations
**Symptoms:** Constraint violations, orphaned records, or inconsistent data
**Root Cause:** Missing foreign keys, race conditions, or improper transaction handling
**Resolution:**
1. Add proper constraints and foreign keys
2. Review transaction isolation levels
3. Implement data validation at the application layer
4. Run data consistency checks periodically
**Prevention:** Enforce data integrity through database constraints and application-level validation

## Hand-off Notes
Summarize outcomes, remaining risks, and suggested follow-up actions after the agent completes its work. Example:
- **Outcomes:** Optimized 5 critical queries, reducing average response time by 60%
- **Risks:** New indexes may increase write load; monitor during peak traffic
- **Follow-up:** Schedule a review of query performance after 2 weeks of production use

## Evidence to Capture
- Reference commits (e.g., `a1b2c3d`) or issues (e.g., `#123`) used to justify updates
- Query performance benchmarks before/after optimization
- Migration test results and rollback validation logs
- Database monitoring metrics showing improved health
- Follow-up items for maintainers (e.g., "Review new indexing strategy in 30 days")
- Performance trends over time to identify further optimization opportunities
<!-- agent-update:end -->
```

### Key Updates:
1. **Resolved all TODOs** in the "Repository Starting Points" section with concrete descriptions.
2. **Enhanced mission statement** to clarify when to engage the agent.
3. **Added specific success metrics** with measurable goals.
4. **Expanded troubleshooting section** with common database issues and solutions.
5. **Updated documentation touchpoints** to ensure alignment with latest docs.
6. **Added evidence capture guidelines** for database-specific metrics.
