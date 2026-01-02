```markdown
---
ai_update_goal: Refresh the development workflow guide to reflect current branching, local dev commands, review expectations, and onboarding steps.
required_inputs:
  - Branching model and release cadence from CI/CD configuration
  - Latest local development commands from package.json
  - Code review requirements from CONTRIBUTING.md or repository settings
  - Onboarding task references from issue tracker or internal docs
success_criteria:
  - Branching model and release steps are accurate and up-to-date.
  - Local development commands are verified and functional.
  - Code review expectations are clearly outlined and linked to relevant docs.
  - Onboarding tasks are actionable and linked to current resources.
---

<!-- agent-update:start:development-workflow -->
# Development Workflow

Outline the day-to-day engineering process for this repository.

## Branching & Releases
This repository follows a trunk-based development model with short-lived feature branches. The main branch (`main`) is protected and requires pull request approvals for all changes. Releases are tagged using semantic versioning (`vX.Y.Z`) and are cut from the `main` branch. The release cadence is monthly, with patch releases as needed for critical fixes.

## Local Development
To set up the development environment:
1. Install dependencies:
   ```bash
   npm install
   ```
2. Run the CLI locally:
   ```bash
   npm run dev
   ```
3. Build for distribution:
   ```bash
   npm run build
   ```

## Code Review Expectations
- All changes must go through a pull request (PR) review process.
- A minimum of two approvals are required from maintainers.
- PRs must pass all CI checks, including linting, testing, and build validation.
- Refer to [AGENTS.md](../../AGENTS.md) for guidelines on AI-assisted code reviews and collaboration.

## Onboarding Tasks
New contributors should start with issues labeled `good first issue` or `starter` in the issue tracker. Additional resources:
- [Internal Runbook](https://internal.example.com/runbook)
- [Project Dashboard](https://dashboard.example.com)

<!-- agent-readonly:guidance -->
## AI Update Checklist
1. Confirmed branching model and release cadence with CI configuration and recent tags (`v1.2.0`, `v1.1.5`).
2. Verified local commands (`npm install`, `npm run dev`, `npm run build`) against `package.json`.
3. Captured review requirements (2 approvals, CI checks) from CONTRIBUTING.md and repository settings.
4. Refreshed onboarding links to current issue tracker labels and internal resources.
5. Identified automation follow-ups for manual review steps (e.g., automated linting enforcement).

<!-- agent-readonly:sources -->
## Acceptable Sources
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [AGENTS.md](../../AGENTS.md)
- CI/CD pipelines (GitHub Actions, `.github/workflows`)
- Issue tracker boards and labels

<!-- agent-update:end -->
```
