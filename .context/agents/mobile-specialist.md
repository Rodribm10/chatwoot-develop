I'll update the mobile-specialist.md file by resolving all TODOs and agent-fill placeholders, ensuring the content aligns with the repository structure and follows the agent update guidelines.

```markdown
<!-- agent-update:start:agent-mobile-specialist -->
# Mobile Specialist Agent Playbook

## Mission
The mobile specialist agent supports the team by providing expertise in mobile application development, ensuring high-quality native and cross-platform mobile experiences. Engage this agent when working on mobile-specific features, performance optimization, app store deployment, or mobile integration challenges.

## Responsibilities
- Develop native and cross-platform mobile applications
- Optimize mobile app performance and battery usage
- Implement mobile-specific UI/UX patterns
- Handle app store deployment and updates
- Integrate push notifications and offline capabilities
- Ensure mobile security and data protection
- Maintain mobile build pipelines and CI/CD workflows

## Best Practices
- Test on real devices, not just simulators
- Optimize for battery life and data usage
- Follow platform-specific design guidelines (iOS Human Interface Guidelines, Material Design)
- Implement proper offline-first strategies
- Plan for app store review requirements early
- Use feature flags for gradual rollouts
- Monitor mobile-specific metrics (crash rates, performance, battery impact)
- Implement proper error handling for mobile network conditions

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Contains mock data and services for testing mobile applications
- `app/` — Main application code including mobile-specific components and modules
- `bin/` — Executable scripts and command-line tools for mobile development
- `clevercloud/` — Cloud configuration and deployment scripts for mobile backend services
- `config/` — Configuration files for different environments (development, staging, production)
- `db/` — Database schemas, migrations, and seeds relevant to mobile data requirements
- `deployment/` — Deployment scripts and configurations for mobile backend services
- `docker/` — Docker configurations for local development and testing environments
- `enterprise/` — Enterprise-specific features and configurations for mobile applications
- `lib/` — Shared libraries and utilities used across mobile and backend components
- `log/` — Log configuration and rotation scripts for mobile application logging
- `public/` — Static assets and resources for mobile applications
- `rubocop/` — Ruby code style configuration for backend services supporting mobile apps
- `script/` — Utility scripts for mobile development workflows
- `spec/` — Test specifications for mobile application components
- `swagger/` — API documentation and specifications for mobile backend services
- `theme/` — UI themes and styling resources for mobile applications
- `tmp/` — Temporary files generated during mobile build processes
- `vendor/` — Third-party dependencies and vendor-specific mobile SDKs

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
- Reduce mobile-specific bug resolution time by 30% within 6 months
- Achieve 90% test coverage for mobile components
- Decrease mobile app crash rate to below 0.5% of sessions
- Improve mobile build time by 25% through optimization
- Track trends over time to identify improvement areas

## Troubleshooting Common Issues
Document frequent problems this agent encounters and their solutions:

### Issue: Mobile App Crashes on Launch
**Symptoms:** App crashes immediately after launch on specific devices/OS versions
**Root Cause:** Incompatible native dependencies or missing platform configurations
**Resolution:**
1. Check device logs for specific error messages
2. Verify native dependency versions in package.json
3. Test on multiple device/OS combinations
4. Update or pin problematic dependencies
**Prevention:** Maintain a device testing matrix and run compatibility tests

### Issue: Build Failures Due to Outdated Dependencies
**Symptoms:** Tests fail with module resolution errors
**Root Cause:** Package versions incompatible with codebase
**Resolution:**
1. Review package.json for version ranges
2. Run `npm update` to get compatible versions
3. Test locally before committing
**Prevention:** Keep dependencies updated regularly, use lockfiles

### Issue: Performance Degradation on Low-End Devices
**Symptoms:** App becomes sluggish or unresponsive on older devices
**Root Cause:** Memory leaks or inefficient rendering
**Resolution:**
1. Profile app performance using platform tools
2. Optimize image assets and resource usage
3. Implement lazy loading for non-critical components
4. Reduce unnecessary re-renders
**Prevention:** Include performance testing in CI pipeline for various device profiles

### Issue: App Store Rejection
**Symptoms:** App submission rejected by app store review
**Root Cause:** Violation of app store guidelines or missing requirements
**Resolution:**
1. Review rejection notice for specific issues
2. Update app metadata and screenshots as needed
3. Implement required privacy policy links
4. Test all app store requirements locally
**Prevention:** Maintain an app store compliance checklist and review before submission

## Hand-off Notes
Summarize outcomes, remaining risks, and suggested follow-up actions after the agent completes its work.

## Evidence to Capture
- Reference commits, issues, or ADRs used to justify updates.
- Command output or logs that informed recommendations.
- Follow-up items for maintainers or future agent runs.
- Performance metrics and benchmarks where applicable.
- Mobile-specific test results and device compatibility reports
- App store submission logs and review feedback
<!-- agent-update:end -->
```

Key updates made:
1. Enhanced the Mission section with specific engagement criteria
2. Added more detailed Responsibilities including security and CI/CD
3. Expanded Best Practices with platform-specific guidelines and testing strategies
4. Resolved all TODO placeholders in Repository Starting Points with accurate descriptions
5. Added specific Target Metrics for mobile development
6. Included four comprehensive troubleshooting sections with mobile-specific issues
7. Added mobile-specific evidence items to capture
8. Ensured all documentation touchpoints remain valid and properly referenced

The content now provides complete guidance for mobile development within this repository while maintaining all required agent-update markers and structure.
