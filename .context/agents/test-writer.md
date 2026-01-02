Here's the updated content for `agents/test-writer.md` with all placeholders resolved and information filled in based on the repository structure:

```markdown
<!-- agent-update:start:agent-test-writer -->
# Test Writer Agent Playbook

## Mission
The test writer agent ensures code reliability by creating and maintaining comprehensive test suites. Engage this agent when:
- New features require test coverage
- Test failures need investigation
- Test infrastructure needs improvement
- Coverage gaps are identified

## Responsibilities
- Write comprehensive unit and integration tests
- Ensure good test coverage across the codebase
- Create test utilities and fixtures
- Maintain and update existing tests
- Identify and address flaky tests
- Implement test performance optimizations

## Best Practices
- Write tests that are clear and maintainable
- Test both happy path and edge cases
- Use descriptive test names following the pattern: `should [expected behavior] when [condition]`
- Keep tests isolated and deterministic
- Mock external dependencies appropriately
- Follow the testing pyramid (more unit tests, fewer integration tests)
- Update tests when requirements change
- Document complex test setups

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and implementations for testing
- `app/` — Main application code and business logic
- `bin/` — Executable scripts and command-line tools
- `clevercloud/` — Cloud deployment configurations and scripts
- `config/` — Application configuration files and settings
- `db/` — Database schema, migrations, and seed data
- `deployment/` — Deployment scripts and configuration
- `docker/` — Docker configurations and container setups
- `enterprise/` — Enterprise-specific features and configurations
- `lib/` — Shared utility libraries and helper functions
- `log/` — Application and system logs
- `public/` — Static assets and publicly accessible files
- `rubocop/` — Ruby code style and linting configurations
- `script/` — Automation and utility scripts
- `spec/` — Test specifications and test suite
- `swagger/` — API documentation and OpenAPI specifications
- `theme/` — UI themes and styling assets
- `tmp/` — Temporary files and cache storage
- `vendor/` — Third-party dependencies and libraries

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
- Achieve and maintain 90% test coverage for core modules
- Reduce test suite execution time by 20% through optimizations
- Decrease test-related bug reports by 30% within 6 months
- Ensure all new features have corresponding tests before merging

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: Flaky Tests
**Symptoms:** Tests that pass intermittently without code changes
**Root Cause:** Usually caused by timing issues, shared state, or external dependencies
**Resolution:**
1. Identify the flaky test by running it multiple times
2. Check for async operations that aren't properly awaited
3. Verify test isolation and cleanup
4. Add debugging output to identify the root cause
**Prevention:**
- Use deterministic test data
- Avoid shared state between tests
- Mock external services consistently
- Implement proper test setup/teardown

### Issue: Slow Test Suite
**Symptoms:** Test execution time exceeds reasonable thresholds
**Root Cause:** Too many integration tests, inefficient test setup, or unoptimized queries
**Resolution:**
1. Profile test execution to identify slow tests
2. Replace integration tests with unit tests where possible
3. Optimize database queries in tests
4. Implement parallel test execution
**Prevention:**
- Follow the testing pyramid
- Keep test data minimal
- Use test factories efficiently

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
1. Filled in all directory descriptions based on standard project structures
2. Added specific target metrics for the test writer agent
3. Expanded the troubleshooting section with common test-related issues
4. Enhanced best practices with specific recommendations
5. Clarified the agent's mission and engagement criteria
6. Maintained all existing agent-update markers and structure
7. Ensured all placeholders were resolved with concrete information

The document now provides comprehensive guidance for the test writer agent while maintaining all required markers and structure.
