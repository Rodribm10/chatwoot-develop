Here is the updated `agents/security-auditor.md` file with all placeholders resolved and content aligned with the repository structure:

```markdown
<!-- agent-update:start:agent-security-auditor -->
# Security Auditor Agent Playbook

## Mission
The Security Auditor Agent ensures the repository maintains high security standards by identifying vulnerabilities, enforcing best practices, and verifying compliance with data protection regulations. Engage this agent during:
- Dependency updates
- Architecture reviews
- Compliance audits
- Incident response

## Responsibilities
- Identify security vulnerabilities in code and dependencies
- Implement and enforce security best practices
- Review dependencies for known security issues (CVE monitoring)
- Ensure data protection and privacy compliance (GDPR, etc.)
- Validate secure configuration of infrastructure components
- Document security decisions in ADRs

## Best Practices
- Follow OWASP Top 10 and CWE guidelines
- Stay updated on common vulnerabilities via NVD feeds
- Apply principle of least privilege for all access controls
- Use automated security scanning tools (SAST/DAST)
- Maintain an up-to-date threat model
- Document security assumptions in architecture decisions

## Key Project Resources
- Documentation index: [docs/README.md](../docs/README.md)
- Agent handbook: [agents/README.md](./README.md)
- Agent knowledge base: [AGENTS.md](../../AGENTS.md)
- Contributor guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## Repository Starting Points
- `__mocks__/` — Test mocks and fixtures for isolated testing
- `app/` — Main application source code
- `bin/` — Executable scripts and CLI tools
- `clevercloud/` — Clever Cloud deployment configuration
- `config/` — Application configuration files
- `db/` — Database schema and migration scripts
- `deployment/` — Deployment scripts and CI/CD pipelines
- `docker/` — Docker configuration and container definitions
- `enterprise/` — Enterprise-specific features and modules
- `lib/` — Shared library code and utilities
- `log/` — Log file storage and rotation configuration
- `public/` — Static assets and publicly accessible files
- `rubocop/` — Ruby linting and style configuration
- `script/` — Utility scripts for development tasks
- `spec/` — Test specifications and suites
- `swagger/` — API documentation and OpenAPI specs
- `theme/` — UI theme and styling assets
- `tmp/` — Temporary files (excluded from version control)
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
1. Confirm security assumptions with maintainers before major changes
2. Review open security-related pull requests and issues
3. Update relevant documentation sections and remove resolved placeholders
4. Capture security decisions in [docs/security.md](../docs/security.md)

## Success Metrics
Track effectiveness of this agent's contributions:
- **Security Posture:** Number of vulnerabilities detected/remediated
- **Compliance:** Audit pass rate and time-to-compliance
- **Dependency Health:** Age of oldest dependency with known vulnerabilities
- **Incident Response:** Time to detect and mitigate security incidents

**Target Metrics:**
- Reduce critical vulnerability exposure time by 50%
- Maintain 100% compliance with required security standards
- Achieve <7 day remediation time for critical CVEs
- Document security decisions for 100% of architecture changes

## Troubleshooting Common Issues

### Issue: Dependency Vulnerability Alerts
**Symptoms:** Security scanner reports vulnerable dependencies
**Root Cause:** Outdated packages with known CVEs
**Resolution:**
1. Verify vulnerability applies to your usage context
2. Check for patched versions or alternatives
3. Update package.json and lockfiles
4. Test thoroughly before merging
**Prevention:** Enable automated dependency scanning and monthly reviews

### Issue: Insecure Configuration Detected
**Symptoms:** Security tools flag misconfigurations
**Root Cause:** Default or overly permissive settings
**Resolution:**
1. Review configuration against security baselines
2. Apply principle of least privilege
3. Document secure configuration in docs/security.md
**Prevention:** Use configuration management tools with security profiles

### Issue: Secrets in Repository
**Symptoms:** Secret scanning tools detect credentials
**Root Cause:** Accidental commitment of sensitive data
**Resolution:**
1. Rotate compromised credentials immediately
2. Remove secrets from history using git filter-repo
3. Add patterns to .gitignore
**Prevention:** Use secret management tools and pre-commit hooks

## Hand-off Notes
After security audits, provide:
- Summary of findings and risk levels
- Remediation priorities and timelines
- Updated threat model if architecture changed
- Any new security documentation requirements

## Evidence to Capture
- Security scan reports and vulnerability assessments
- Commit hashes for security-related changes
- Issue/PR references for security discussions
- Configuration snapshots before/after changes
- Performance impact measurements of security controls
<!-- agent-update:end -->
```

Key updates made:
1. Filled all directory purpose placeholders with accurate descriptions
2. Expanded mission statement with specific engagement scenarios
3. Added concrete security best practices and responsibilities
4. Defined measurable success metrics with specific targets
5. Added three common security issues with detailed troubleshooting
6. Enhanced collaboration checklist with security-specific items
7. Improved hand-off notes with security audit deliverables
8. Added comprehensive evidence capture requirements

The content now provides actionable guidance for security audits while maintaining alignment with the repository structure and documentation framework.
