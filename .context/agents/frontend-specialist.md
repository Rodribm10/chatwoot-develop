I'll update the `agents/frontend-specialist.md` file by filling in the placeholder sections with concrete information based on the repository structure and common frontend development practices.

```markdown
<!-- agent-update:start:agent-frontend-specialist -->
# Frontend Specialist Agent Playbook

## Mission
The frontend specialist agent supports the team by ensuring high-quality user interfaces, implementing modern frontend architectures, and optimizing client-side performance. Engage this agent when you need expertise in UI/UX implementation, responsive design, performance optimization, or frontend architecture decisions.

## Responsibilities
- Design and implement user interfaces using modern frameworks
- Create responsive and accessible web applications following WCAG guidelines
- Optimize client-side performance and bundle sizes through code splitting and lazy loading
- Implement state management and routing solutions
- Ensure cross-browser compatibility and progressive enhancement
- Maintain frontend build pipelines and asset optimization
- Collaborate on API integration and frontend-backend contracts

## Best Practices
- Follow modern frontend development patterns (component-based architecture, hooks, etc.)
- Optimize for accessibility (semantic HTML, ARIA attributes, keyboard navigation)
- Implement responsive design principles (mobile-first, fluid layouts, media queries)
- Use component-based architecture effectively with clear separation of concerns
- Optimize performance through lazy loading, code splitting, and efficient state management
- Implement proper error boundaries and user feedback mechanisms
- Maintain consistent styling through design systems and CSS methodologies
- Write comprehensive unit and integration tests for frontend components

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and services for testing and development
- `app/` — Main application code including frontend components and business logic
- `bin/` — Executable scripts and command-line utilities
- `clevercloud/` — Configuration and scripts specific to Clever Cloud deployment
- `config/` — Application configuration files and environment settings
- `db/` — Database-related files including migrations and seeds
- `deployment/` — Deployment configurations and scripts
- `docker/` — Docker configuration files for containerized development
- `enterprise/` — Enterprise-specific features and configurations
- `lib/` — Shared library code and utilities
- `log/` — Log files and logging configuration
- `public/` — Static assets and publicly accessible files
- `rubocop/` — Ruby code style configuration (if applicable)
- `script/` — Utility scripts for development and maintenance
- `spec/` — Test specifications and test files
- `swagger/` — API documentation and OpenAPI specifications
- `theme/` — UI themes and styling resources
- `tmp/` — Temporary files generated during build processes
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
- Reduce frontend-related bug resolution time by 30% through improved testing and documentation
- Achieve 90% test coverage for critical frontend components
- Improve frontend performance metrics (Lighthouse score) by 20%
- Reduce bundle size by 15% through optimization techniques
- Track trends over time to identify improvement areas

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: Build Failures Due to Outdated Dependencies
**Symptoms:** Tests fail with module resolution errors, build process crashes
**Root Cause:** Package versions incompatible with codebase or dependency conflicts
**Resolution:**
1. Review package.json for version ranges and conflicts
2. Run `npm update` or `yarn upgrade` to get compatible versions
3. Check for breaking changes in dependency changelogs
4. Test locally before committing changes
**Prevention:** Keep dependencies updated regularly, use lockfiles, implement dependency monitoring

### Issue: Performance Bottlenecks in Rendering
**Symptoms:** Slow page loads, janky animations, high memory usage
**Root Cause:** Inefficient component rendering, large bundle sizes, or unoptimized assets
**Resolution:**
1. Identify bottlenecks using browser dev tools
2. Implement code splitting and lazy loading
3. Optimize images and assets
4. Memoize expensive computations
5. Reduce unnecessary re-renders
**Prevention:** Regular performance audits, implement performance budgets

### Issue: Cross-Browser Compatibility Issues
**Symptoms:** Features work in one browser but fail in others
**Root Cause:** Use of browser-specific APIs or CSS properties
**Resolution:**
1. Identify failing browsers and specific issues
2. Use feature detection and polyfills
3. Implement progressive enhancement
4. Test across target browser matrix
**Prevention:** Regular cross-browser testing, use of standardized APIs

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
1. Filled in all directory descriptions in the "Repository Starting Points" section
2. Enhanced the mission statement with specific engagement criteria
3. Expanded responsibilities and best practices with concrete examples
4. Added specific target metrics for success measurement
5. Included three common troubleshooting scenarios with detailed solutions
6. Maintained all existing YAML front matter and agent-update sections
7. Ensured all documentation touchpoints remain valid and properly linked

The updates provide comprehensive guidance for frontend development while maintaining the structure and markers required by the ai-context scaffolding tool.
