---
name: api-testing
description: Builds safe, authorized API abuse testing plans for applications. Use when testing APIs for broken access control, data exposure, unsafe input handling, replay, rate-limit gaps, or business logic abuse.
allowed-tools: Read Grep Glob Bash Write
---

# API Testing

Use this skill to create a practical security test plan for APIs. The output should help a startup engineering team or enterprise security team test realistic abuse cases without turning the report into an offensive payload catalog.

The skill can be used against repository code, OpenAPI specs, route definitions, API docs, Postman collections, test suites, logs, or a local authorized environment.

## Safety Boundaries

- Only plan or run tests against systems the user owns or is authorized to test.
- Prefer local, staging, or explicitly approved test environments.
- Do not include destructive payloads, persistence steps, credential theft workflows, or attack instructions against third-party systems.
- For production systems, recommend non-destructive validation and rate-limited probes only when explicitly authorized.
- Do not run high-volume, destructive, or state-changing tests without user approval.

## Discovery

Identify:

- API styles: REST, GraphQL, gRPC, WebSocket, webhooks, internal RPC, worker events, or SDK methods.
- Auth mechanisms: sessions, bearer tokens, API keys, OAuth, SSO, mTLS, signed webhooks, service accounts.
- Actor types: anonymous, user, admin, tenant member, external integration, service account, internal support, CI/deploy actor.
- Sensitive operations: login, reset, invite, role change, export, billing, deletion, file upload, integration setup, webhook handling, import, search, report generation.
- Data types: PII, credentials, tokens, tenant data, customer data, payments, audit logs, prompts, model outputs, files, operational metadata.
- Existing tests: unit, integration, E2E, contract tests, DAST, fuzzing, negative auth tests.

Useful commands when available:

```sh
rg --files
rg -n "router|route|controller|handler|resolver|mutation|query|webhook|OpenAPI|swagger|graphql|grpc"
rg -n "auth|permission|role|tenant|org|admin|api.?key|token|rate.?limit|csrf|cors|upload|export|invite|billing"
```

## Test Categories

Build test cases across categories relevant to the target:

### Access Control

- Unauthenticated access to protected endpoints.
- Low-role access to privileged actions.
- Cross-user and cross-tenant object access by changing IDs.
- Bulk operations where only some objects are authorized.
- Admin/support/impersonation boundaries.
- API key scope and service-account boundaries.

### Data Exposure

- Sensitive fields in responses, errors, logs, exports, search, list endpoints, autocomplete, analytics, cache keys, and metadata.
- Server-only data in client-visible APIs.
- Debug, health, metrics, or internal endpoints exposed to the wrong actor.

### Input Handling

- Type confusion, schema bypass, over-posting, mass assignment, unsafe filters, sorting, path traversal, file upload edge cases, parser limits, and unsafe URL fetches.
- GraphQL depth, alias, introspection, batching, and resolver-level authorization.

### Replay And Workflow Abuse

- Reusing one-time tokens, reset links, invites, checkout sessions, approval links, signed URLs, webhook events, or idempotency keys.
- Skipping workflow steps or changing state out of order.
- Race conditions around billing, quotas, inventory, approvals, and role changes.

### Rate Limits And Resource Abuse

- Expensive search, export, report, upload, import, AI/tool, or webhook endpoints.
- Missing per-user, per-tenant, per-IP, and per-key limits.
- Queue amplification, retry storms, and background job abuse.

### Integration And Webhooks

- Signature verification, timestamp windows, replay protection, event-to-tenant binding, external ID mapping, and failure modes.
- Integration install/uninstall and permission downgrade behavior.

### LLM Or Agent APIs

- Prompt injection into tool calls.
- Untrusted content influencing privileged actions.
- Cross-tenant retrieval or memory leakage.
- Tool permission and human-approval boundaries.

## Output Format

Produce an actionable CSV list of planned API security test cases:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `planned_test`, `confirmed_gap`, `needs_environment`, `do_not_run_without_approval`, or `no_confirmed_findings`. Use `category` values such as `access-control`, `data-exposure`, `input-handling`, `replay`, `workflow-abuse`, `rate-limit`, `webhook`, `integration`, `graphql`, `llm-agent`, or `operability`.

For planned tests, use:

- `location`: endpoint, resolver, webhook, job, or API family.
- `asset_or_flow`: protected data, action, workflow, or state transition.
- `actor`: required test actor or role setup.
- `issue`: risk the test is designed to prove or disprove.
- `impact`: why the control matters.
- `evidence`: response, log, assertion, audit event, or metric to collect.
- `fix`: likely control to add if the test fails.
- `test`: safe test idea or automation target.
- `scope_notes`: environment, data, rate limits, and approval requirements.

Put scope, coverage matrix, automation recommendations, and tests that must not run without approval after the CSV unless the user asks for CSV only.

## Quality Bar

- Prioritize tests by business risk and likelihood.
- Include negative authorization tests for every sensitive API family.
- Prefer reusable test patterns teams can automate in CI.
- Clearly mark tests that require staging data, privileged accounts, or production approval.
- Include what evidence proves the control works.
- When a safe local environment exists, run representative smoke tests with local fixtures or temporary stubs for external integrations, then clean up scratch requests, local data, mock servers, and temporary config.
- Do not stub the API control being tested: authorization, signature verification, rate limiting, replay protection, validation, and tenant filters must be exercised for real.
- When subagents are available, ask an independent subagent to review high-priority test cases for missing actor setups, false assumptions, unsafe production impact, and whether the expected secure behavior is measurable.
