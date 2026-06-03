---
name: security-tests
description: Converts security findings, threat models, PR review concerns, and suspected vulnerabilities into concrete regression tests. Use when adding or proposing tests that prove an application's security controls keep working.
allowed-tools: Read Grep Glob Bash Write
---

# Security Tests

Use this skill when a team has a security concern, finding, PR risk, or threat model and needs durable tests that prevent the bug class from returning.

The goal is not just to test the patch. The goal is to encode the security property that must remain true.

## Principles

- Test the security invariant, not an incidental implementation detail.
- Prefer denial tests for unauthorized actors and malicious inputs.
- Use existing test frameworks and project patterns.
- Keep tests deterministic and local when possible.
- Do not add brittle tests that require real third-party services unless the repo already has a stable harness.
- Do not introduce broad mocks that skip the security control being tested.
- Use temporary stubs only for external services, credentials, time, network, or nondeterministic providers. The authentication, authorization, tenant filter, validation, approval, signature, or policy control being tested must run for real.
- Clean up exploratory scratch files, throwaway harnesses, temporary data, and local config changes before final output. Keep only intentional regression tests that the user asked you to add.
- When subagents are available, ask an independent subagent to review proposed or added tests for whether they would fail against the vulnerable behavior and whether they accidentally mock away the security boundary.

## Inputs

Accept any of:

- A vulnerability finding.
- A PR security review.
- A threat scenario.
- A suspected bug.
- A patch that needs validation.
- A security requirement such as "users cannot access other tenants' data."

First identify:

- The security property.
- The affected entry point.
- The attacker starting permissions.
- The protected asset or action.
- The expected secure failure mode.
- The existing test framework and fixtures.

## Test Patterns

Use the pattern that best matches the risk:

### Authorization

- User A cannot read/write/delete/export User B's object.
- Tenant A cannot access Tenant B's records by swapping IDs.
- Viewer/member cannot perform admin/owner actions.
- Revoked or disabled identities lose access.
- Bulk endpoints enforce authorization per object.

### Authentication And Sessions

- Missing, expired, malformed, revoked, wrong-audience, or wrong-issuer tokens fail.
- Logout and password reset invalidate the right sessions.
- OAuth/SSO callbacks reject forged state, wrong redirect, or wrong issuer.

### Input Handling

- Unsafe input is rejected or encoded in the correct context.
- Raw query, shell, path, template, parser, and URL fetch paths cannot be controlled by user input.
- File upload validation covers type, size, extension, content, path, and parser limits.

### Data Exposure

- Sensitive fields are absent from API responses, logs, exports, telemetry, errors, and client bundles.
- Debug/internal endpoints are not accessible to unauthorized actors.

### Webhooks And Integrations

- Invalid signatures fail.
- Old timestamps fail.
- Replayed events fail or are idempotent.
- Events are bound to the correct tenant or account.

### LLM And Agentic Systems

- Untrusted content cannot trigger privileged tools.
- Retrieved content from one tenant cannot affect another tenant.
- Model output is validated before shell, browser, network, database, or policy actions.

### Supply Chain And CI

- Security-sensitive workflow permissions remain least-privilege.
- Release jobs require expected checks.
- Build scripts do not expose secrets.

## Implementation Workflow

1. Read existing tests and fixtures before writing new tests.
2. Locate the smallest test layer that exercises the real control.
3. Create realistic actors, tenants, resources, and malicious inputs.
4. Assert the secure behavior clearly: denied status, exception, no state change, no log field, no queued job, no cross-tenant row.
5. Add a positive control only when needed to prove the setup is valid.
6. Run the targeted test command.
7. Remove temporary validation scaffolding that is not part of the intended test change.
8. If the test cannot be added, produce a precise test plan with file locations and fixture needs.

## Output Format

When editing or proposing tests, output a CSV list of security test coverage:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `test_added`, `test_proposed`, `test_failed`, `blocked`, `residual_gap`, or `no_confirmed_findings`. Use `category` values such as `authorization`, `authentication`, `input-handling`, `data-exposure`, `webhook`, `llm-agent`, `supply-chain`, or `coverage`.

For test rows, use:

- `location`: test file path or proposed file path.
- `asset_or_flow`: protected asset, action, endpoint, tool, workflow, or policy.
- `actor`: unauthorized or malicious actor setup.
- `issue`: security invariant being encoded.
- `impact`: bug class or finding this prevents.
- `evidence`: command result, file created, or fixture inspected.
- `fix`: production control the test protects.
- `test`: test name and expected secure failure mode.
- `scope_notes`: residual gaps, setup requirements, or why a test could not be added.

Put verification commands, residual gaps, and a concise coverage summary after the CSV unless the user asks for CSV only.

## Quality Bar

- Each high or critical finding should have at least one regression test.
- Tests should fail against the vulnerable behavior and pass against the fix.
- Tests should be readable enough that future maintainers understand the security property.
- Avoid overfitting to one parameter name when the real property is broader.
