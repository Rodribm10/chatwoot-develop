```markdown
<!-- agent-update:start:tooling -->
# Tooling & Productivity Guide

Collect the scripts, automation, and editor settings that keep contributors efficient.

## Required Tooling
- **Node.js (v18+)** — Required for running the application and scripts. Install via [nvm](https://github.com/nvm-sh/nvm) or [Node.js official installer](https://nodejs.org/). Powers the backend, frontend build tools, and testing frameworks.
- **Docker (v20+)** — Used for local development and deployment. Install from [Docker's official site](https://www.docker.com/). Required for running the application in containerized environments.
- **Git (v2.30+)** — Version control system. Install from [Git's official site](https://git-scm.com/). Used for cloning the repository and managing code changes.
- **Yarn (v1.22+)** — Package manager for Node.js dependencies. Install via `npm install -g yarn`. Used for managing project dependencies and running scripts.

## Recommended Automation
- **Pre-commit Hooks**: Configured via `husky` and `lint-staged` to run linting and formatting checks before commits. Ensure you have these installed by running `yarn install`.
- **Linting/Formatting**: Use `yarn lint` to run ESLint and `yarn format` to run Prettier. These commands ensure code consistency and catch potential issues early.
- **Code Generators**: Utilize the `ai-context` scaffolding tool for generating documentation and agent playbooks. Run `yarn generate-docs` to refresh documentation based on the latest repository state.
- **Scaffolding Scripts**: Use the scripts in the `bin/` directory for common tasks such as setting up the development environment or deploying the application.

## IDE / Editor Setup
- **VS Code Extensions**:
  - **ESLint**: Integrates ESLint into VS Code for real-time linting.
  - **Prettier**: Automatically formats code on save.
  - **Docker**: Provides tools for managing Docker containers and images.
  - **GitLens**: Enhances Git capabilities within VS Code.
- **Snippets**: Shared code snippets are available in the `.vscode/` directory. These include common patterns and templates used across the project.
- **Workspace Settings**: Configured in `.vscode/settings.json` to ensure consistent editor settings across the team.

## Productivity Tips
- **Terminal Aliases**: Add the following aliases to your shell configuration for quicker navigation and command execution:
  ```bash
  alias dc="docker-compose"
  alias dcu="docker-compose up -d"
  alias dcd="docker-compose down"
  alias ylint="yarn lint"
  alias yformat="yarn format"
  ```
- **Container Workflows**: Use Docker Compose to manage local development environments. Run `docker-compose up -d` to start the application and its dependencies.
- **Local Emulators**: Use the `clevercloud/` directory to set up local emulators that mirror production environments. Refer to the `clevercloud/README.md` for detailed instructions.

## AI Update Checklist
1. Verify commands align with the latest scripts and build tooling.
2. Remove instructions for deprecated tools and add replacements.
3. Highlight automation that saves time during reviews or releases.
4. Cross-link to runbooks or README sections that provide deeper context.

## Acceptable Sources
- Onboarding docs, internal wikis, and team retrospectives.
- Script directories, package manifests, CI configuration.
- Maintainer recommendations gathered during pairing or code reviews.

<!-- agent-update:end -->
```
