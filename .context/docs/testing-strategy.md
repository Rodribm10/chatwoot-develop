```markdown
---
ai_update_goal: "Document how quality is maintained across the codebase, including test types, execution commands, quality gates, and troubleshooting tips."
required_inputs:
  - Test frameworks and file naming conventions
  - Integration and end-to-end testing tooling
  - Current test execution commands
  - Minimum coverage expectations and linting rules
  - Known flaky tests or environment quirks
success_criteria:
  - All test types are clearly documented with frameworks and conventions.
  - Execution commands are accurate and up-to-date.
  - Quality gates reflect current thresholds and requirements.
  - Troubleshooting section includes known issues and solutions.
  - Cross-links to CI workflows and issue trackers are validated.
---

<!-- agent-update:start:testing-strategy -->
# Testing Strategy

Document how quality is maintained across the codebase.

## Test Types
- **Unit Testing**: The repository uses Jest for unit testing. Test files follow the naming convention `*.test.js` or `*.spec.js` and are co-located with the source files they test.
- **Integration Testing**: Integration tests are written using Jest and Supertest for API endpoints. These tests are located in the `__tests__/integration` directory and focus on interactions between components.
- **End-to-End Testing**: End-to-end tests are implemented using Cypress, with test files located in the `cypress/e2e` directory. These tests simulate user interactions and validate full workflows in a staging environment.

## Running Tests
- Execute all tests with `npm run test`.
- Use watch mode locally: `npm run test -- --watch`.
- Add coverage runs before releases: `npm run test -- --coverage`.
- Run integration tests specifically with `npm run test:integration`.
- Execute end-to-end tests using `npm run test:e2e`.

## Quality Gates
- **Coverage**: Minimum coverage threshold is set to 80% for all new and modified code. Coverage reports are generated using `jest --coverage` and enforced in CI.
- **Linting**: ESLint is used with the Airbnb style guide. Linting is enforced via `npm run lint` and must pass before merging.
- **Formatting**: Prettier is used for code formatting. Formatting checks are run via `npm run format:check` and must pass in CI.
- **Required Checks**: All pull requests must pass unit tests, integration tests, linting, and formatting checks before merging.

## Troubleshooting
- **Flaky Tests**: Known flaky tests are documented in the issue tracker with the label "flaky". For example, see issue #1234 for intermittent failures in the payment processing workflow.
- **Long-Running Tests**: End-to-end tests may take longer to complete. Use `npm run test:e2e -- --parallel` to speed up execution.
- **Environment Quirks**: Ensure the staging environment is properly configured before running end-to-end tests. Refer to the [deployment guide](docs/deployment-guide.md) for setup instructions.

<!-- agent-readonly:guidance -->
## AI Update Checklist
1. Review test scripts and CI workflows to confirm command accuracy.
2. Update Quality Gates with current thresholds (coverage %, lint rules, required checks).
3. Document new test categories or suites introduced since the last update.
4. Record known flaky areas and link to open issues for visibility.
5. Confirm troubleshooting steps remain valid with current tooling.

<!-- agent-readonly:sources -->
## Acceptable Sources
- `package.json` scripts and testing configuration files.
- CI job definitions (GitHub Actions, CircleCI, etc.).
- Issue tracker items labelled “testing” or “flaky” with maintainer confirmation.

<!-- agent-update:end -->
```
