---
name: pr-review
description: Reviews PR or branch diffs, threat models the changed behavior, and reports net-new security vulnerabilities, correctness bugs, and operability regressions. Use for detailed security and correctness reviews of PRs, branches, patches, or diffs before merge.
allowed-tools: Read Grep Glob Bash
---

# PR Review

Use this skill when reviewing a pull request, branch, patch, or diff for security and correctness impact. The goal is to understand what behavior the change alters, threat model that changed behavior, and report only net-new, newly exposed, or regressed issues.

This skill is written for Claude Code, Codex, Cursor, and similar coding agents. Tool names vary by environment; use local equivalents for Git inspection, file search, file reading, shell commands, and test execution.

This skill is intentionally orthogonal to `code-quality`. This one asks: "Could this change break behavior, weaken security, leak data, or surprise users?" Maintainability and boundary concerns belong in `code-quality`.

## Core Principle

The diff is the starting point, not the whole review. A serious review follows changed code outward until it understands the affected entry points, trust boundaries, data flows, permissions, contracts, and runtime behavior.

Report a finding only when the change introduces, exposes, weakens, or makes reachable a security risk, correctness regression, or operability problem. If the change touches existing vulnerable code but does not change its reachability or impact, call that out separately as pre-existing risk.

## Ground Rules

- Review the diff first. Treat the diff as primary evidence.
- Do not rabbit-hole into unrelated pre-existing code.
- Read surrounding code only when needed to prove reachability, understand contracts, or verify a changed behavior.
- Do not read PR comments, review threads, or bot output until after the independent audit is complete. Avoid anchoring.
- Report only issues introduced, exposed, or materially worsened by this change.
- Separate pre-existing risk from diff-introduced findings.
- Do not modify code unless the user explicitly asks for fixes.

## Scope Rules

Classify each issue as one of:

- `Net-new`: introduced by the change.
- `Newly exposed`: pre-existing risky code becomes reachable, privileged, externally accessible, or more impactful because of the change.
- `Regression`: the change removes, bypasses, or weakens an existing control or correct behavior.
- `Pre-existing`: relevant context, but not introduced or worsened by the change.
- `Needs verification`: plausible change-linked concern that lacks enough evidence.

Only `Net-new`, `Newly exposed`, and `Regression` belong in `Findings`. Put `Pre-existing` and `Needs verification` in separate sections.

## Setup And Diff Discovery

First determine the review target:

1. If a PR number or URL is provided, inspect PR metadata, changed files, commits, and diff.
2. If a branch is checked out, compare it to the appropriate base branch.
3. If only local changes exist, review staged and unstaged diffs.
4. If the base is ambiguous, infer it from upstream metadata, PR metadata, or the default branch. Ask only if ambiguity affects correctness.

Useful commands when available:

```sh
git status --short --branch
git diff --stat BASE...HEAD
git diff BASE...HEAD
git diff --cached
git merge-base HEAD origin/main
gh pr view --json number,title,body,baseRefName,headRefName,author,files,commits,reviews,statusCheckRollup
gh pr diff
```

Use read-only GitHub commands when authenticated and appropriate. Do not post comments, approve, request changes, push, or modify PR state unless the user explicitly asks.

## Phase 1: Understand The Change Intent

Before reviewing for vulnerabilities, summarize internally:

- What user-visible or system behavior changes?
- Which components, services, jobs, schemas, APIs, routes, policies, or workflows changed?
- What security boundaries does the change touch?
- What sensitive assets or privileged operations does it affect?
- What tests were added, removed, or changed?
- What deployment, CI, infra, or dependency changes are included?
- Does the PR description match the actual diff?

Treat mismatch between stated intent and actual security-relevant behavior as a review signal.

## Phase 2: Build A Changed-Flow Threat Model

For each security-relevant changed flow, model:

- Entry point: route, handler, job, webhook, CLI, UI action, worker, queue event, scheduled task, migration, or build/deploy step.
- Actors: anonymous user, authenticated user, tenant member, admin, support user, service account, internal service, third-party provider, CI actor, or attacker.
- Trust boundary: browser to server, user to tenant, tenant to tenant, user to admin, app to third party, app to database, worker to infrastructure, model output to tool.
- Sensitive assets: sessions, tokens, secrets, customer data, tenant data, payments, PII, logs, source code, prompts, model outputs, infra credentials, admin actions.
- Controls added, removed, changed, or assumed: authentication, authorization, tenant filters, validation, output encoding, CSRF, CORS, rate limits, audit logs, encryption, sandboxing, policy checks, tests.
- Failure modes: what happens if inputs are malicious, identities are low-privilege, tenants are different, third-party callbacks are forged, queues are replayed, or model outputs are hostile.

The threat model should be proportional to the change. A small auth change may require deeper analysis than a large UI-only change.

## Phase 3: Expand Context Deliberately

Read surrounding code until you can prove or disprove reachability:

- Callers and callees of changed functions.
- Route registration and middleware order.
- Auth and authorization helpers.
- Schema/model relationships and migrations.
- Database queries and tenant filters.
- Feature flags and config defaults.
- Worker/event producers and consumers.
- Tests for changed behavior and security properties.
- Existing patterns in adjacent code.

Do not rewrite a whole repo review. Expand only where needed to answer whether the change introduces a real issue.

Useful search patterns:

```sh
rg -n "changedFunction|ChangedClass|routeName|permissionName|policyName"
rg -n "auth|session|token|tenant|org|role|permission|policy|admin|webhook|secret|encrypt|decrypt|jwt|oauth|csrf|cors|rate|limit"
rg -n "TODO|FIXME|SECURITY|unsafe|bypass|skip|allow|deny|public|internal"
```

## Phase 4: Review Domains

Review every domain touched by the change. Be especially suspicious when the change adds new entry points, broadens access, moves checks, changes schemas, adds integrations, changes default config, or changes CI/deploy behavior.

### Security

#### Authentication And Sessions
- New unauthenticated routes or callbacks.
- Login, signup, password reset, invitation, SSO, OAuth, SAML, magic-link, API-key, or service-account changes.
- Token parsing, verification, expiry, storage, rotation, revocation, cookie flags, redirect handling, and session fixation.
- Middleware order changes that can bypass auth.
- Email change, account linking, MFA enrollment or recovery, remember-device, impersonation, support-access, and session step-up changes.
- JWT algorithm handling, decode-without-verify paths, issuer or audience validation, JWKS refresh behavior, and whether new code trusts token headers or claims before verification.
- Refresh-token rotation changes: whether old tokens are invalidated, token families are tracked, reuse is detected, and logout, password reset, or account disablement revoke the intended sessions.
- OAuth/SSO/SAML callback changes: state or nonce validation, redirect URI tampering, issuer mismatch, assertion replay, default role assignment, invite binding, and cross-tenant or cross-environment account confusion.
- Password reset and magic-link changes: token entropy, single-use guarantees, short expiry, secure delivery, replay resistance, and leakage into logs, analytics, referrers, or error messages.
- MFA changes: bypass via alternate endpoints, race or replay on challenge completion, backup-code reuse, recovery flow weakening, or failures to require step-up auth before sensitive actions.
- Cookie and browser-facing auth changes: `HttpOnly`, `Secure`, `SameSite`, path and domain scope, bearer tokens moving into browser storage, and redirects that can strand auth codes or tokens in URLs.

#### Authorization And Tenant Isolation
- Object-level checks missing from new reads, writes, deletes, exports, and state transitions.
- Cross-tenant filters removed, weakened, or applied after data access.
- New batch endpoints, admin paths, support tooling, impersonation, sharing, or invite flows.
- Worker jobs or webhooks that trust user-controlled IDs.
- UI-only authorization assumptions.

#### Data Exposure
- New logs, traces, analytics, error messages, client responses, exports, cache keys, URLs, browser storage, or support tooling that include sensitive data.
- Server-only data moving into client bundles or public APIs.
- Debug endpoints, verbose errors, stack traces, or new metadata leaks.

#### Injection And Unsafe Execution
- Raw SQL/NoSQL, dynamic query construction, shell commands, template rendering, eval-like behavior, deserialization, XML/YAML parsing, dynamic imports, path joins, archive extraction, and regex denial-of-service.
- User-controlled input reaching dangerous sinks through new code paths.
- Sanitization that is context-insensitive or applied too late.

#### SSRF, File, Parser, And Egress Risk
- New URL fetchers, webhook testers, importers, crawlers, preview generators, file uploads, parsers, storage integrations, PDF/image/video processors, or metadata fetches.
- Missing redirect handling, private IP blocking, DNS rebinding protection, file path normalization, symlink checks, content-type validation, size limits, and timeouts.

#### LLM And Agentic Systems
- Untrusted prompt, webpage, file, email, ticket, or document content influencing privileged tools.
- Model output used as shell, browser, SQL, code, policy, or network instructions.
- Cross-tenant retrieval, memory, vector-store, prompt, trace, or tool-output leakage.
- Missing tool permission boundaries or human approval for sensitive actions.

#### Business Logic And Abuse
- Quota, billing, trial, referral, approval, reset, invite, role change, export, marketplace, workflow-state, or race-condition changes.
- New unauthenticated expensive operations or amplified background jobs.
- Idempotency and replay protection changes.

#### Supply Chain, CI, And Deployment
- New dependencies, install scripts, GitHub Actions permissions, secrets exposure, build steps, release automation, Dockerfile changes, generated code, artifact publishing, and environment default changes.
- Whether dependency changes introduce known security alerts when tooling is available.

#### Cryptography And Secrets
- Randomness, password hashing, signing, encryption, JWT verification, webhook signatures, key management, config defaults, secret storage, and test fixtures.
- Secret values or credentials added to code, logs, docs, tests, or examples.

### Correctness

- Broken API contracts, schema mismatches, migrations, serialization changes, and backwards compatibility.
- Feature flags that leak unfinished behavior, bypass checks, or default to unsafe states.
- Error handling that hides failures, retries forever, drops work, or corrupts state.
- Race conditions, idempotency regressions, duplicate processing, ordering bugs, stale cache behavior.
- Timezone, pagination, filtering, sorting, null handling, enum, precision, and boundary bugs.
- Concurrency, async, queue, worker, cron, and transaction semantics.
- Performance or resource regressions that can trigger incidents or denial of service.

### Developer Experience And Operability

- Build, test, lint, migration, seed, local dev, or generated-code regressions.
- Logging and observability changes that make incidents harder to debug.
- Configuration defaults that make safe local or staging use harder.
- Error messages that mislead operators or users.

### Tests And Regression Coverage

Look for tests that prove:
- Low-privilege users cannot perform privileged actions.
- Tenant A cannot access tenant B.
- Unauthenticated callers are rejected.
- Invalid tokens and forged callbacks fail.
- Expired, malformed, revoked, wrong-issuer, or wrong-audience tokens fail.
- Logout, password reset, tenant removal, or account disablement invalidate the intended sessions.
- Refresh-token replay and MFA bypass attempts fail and emit a measurable denial path.
- Cross-user session reuse, forged magic links, and OAuth state or redirect tampering fail.
- Malicious input is rejected or safely encoded.
- Sensitive data is not logged or returned.
- Limits, timeouts, and replay/idempotency protections hold.
- Migrations remain compatible with prior code paths during rolling release.

Missing tests are not automatically a vulnerability, but they lower confidence and can be a finding when the change alters a high-risk control or contract.

## Finding Standard

A finding must answer:

- What exact change introduced or exposed the risk?
- What changed flow or behavior is affected?
- What security property, correctness contract, or operational invariant fails?
- What attacker starting position is realistic (for security findings)?
- What trust boundary is crossed?
- What control is missing, weakened, removed, or bypassed?
- What sensitive asset, permission, tenant, operation, or system state is impacted?
- Why existing code or tests do not already prevent it?
- What evidence proves this is reachable or likely?
- What minimal fix would close the issue?
- What regression test should be added?

Do not report style issues or generic best practices. Do not report vulnerabilities solely because a dangerous-looking API exists. Put maintainability and boundary concerns in `code-quality`. Prove the path from change to impact.

## Severity

Rate based on the reachable delta introduced by the change:

- Critical: reliable unauthorized access to highly sensitive data, cross-tenant compromise, privileged system control, server-side code execution, data loss/corruption, production outage, or irreversible business impact.
- High: auth bypass, privilege escalation, sensitive data disclosure, significant tenant isolation failure, secret exposure, powerful SSRF/unsafe execution, major correctness regression, unsafe deploy path, or likely incident.
- Medium: scoped data exposure, partial authorization bypass, meaningful abuse, SSRF with limited reach, weak control change, important behavior break, fragile migration, meaningful operational regression, or incomplete safety control.
- Low: limited hardening issue, narrow bug, edge-case correctness issue, or minor operational regression with narrow or unlikely impact.
- Informational: relevant observation without confirmed impact.

Include confidence separately: High, Medium, or Low.

## Validation

- Run focused local tests, lint checks, build checks, migration checks, or smoke tests for high-confidence findings when the repo provides a clear, fast, safe command.
- Use temporary stubs or mock services only to isolate external providers, unavailable credentials, slow dependencies, or nondeterministic behavior. Do not stub out the changed contract or security control being reviewed.
- Remove temporary stubs, scratch files, local config changes, and ad hoc scripts before final output unless the user explicitly asked for test implementation.
- When subagents are available, ask an independent subagent to challenge each confirmed high or critical finding — whether the change really introduced the issue and whether the impact is overstated — before reporting it.

## Output Format

Lead with a CSV findings list. Keep the changed-flow threat model concise and secondary.

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values: `net_new`, `newly_exposed`, `regression`, `pre_existing`, `needs_verification`, or `no_confirmed_findings`. Use `category` values: `authorization`, `authentication`, `session`, `token-handling`, `oauth-sso`, `mfa`, `account-takeover`, `data-exposure`, `injection`, `ssrf`, `secrets`, `supply-chain`, `llm-agent`, `business-logic`, `abuse`, `correctness`, `operability`, `devex`, or `tests`.

Example rows:

```csv
F-001,high,high,net_new,authorization,New batch update trusts request tenant id,api/routes/projects.py:74,batch project update,tenant member,The change adds batch updates keyed by tenant_id from the request body without per-project membership checks,Tenant member can modify projects outside their tenant,Diff adds tenant_id body field and service updates all matching ids before policy enforcement,Derive tenant from authenticated actor and authorize each project id,Add cross-tenant batch update denial test,Base origin/main head feature/batch-update
F-002,medium,high,regression,correctness,Migration drops nullable default used by old workers,db/migrations/20260603.sql:12,job creation flow,background worker,The diff makes status non-null without backfilling rows old workers create without status,Deploy can fail or drop queued work during rolling release,Migration changes constraint while worker code in base still inserts missing status,Backfill and deploy code that writes status before enforcing non-null,Add migration compatibility test,Reviewed BASE...HEAD migration and worker insert path
F-003,high,high,regression,oauth-sso,OAuth callback stops validating state before account linking,auth/oauth/callback.ts:91,OAuth account linking callback,authenticated user,The change links the provider identity to the signed-in account before checking the stored state nonce,An attacker can bind their provider response to another user's active browser session and take over the linked login path,Diff moves account-linking logic ahead of the existing state check and no replacement validation remains,Validate state and nonce before any account lookup or linking side effect,Add forged OAuth callback denial and cross-user account-linking tests,Reviewed diff and adjacent auth callback helpers
```

If no change-introduced issues are found, still emit the header and one `no_confirmed_findings` informational row. Put the changed-flow threat model, pre-existing risks, needs-verification items, coverage, and residual risk after the CSV unless the user asks for CSV only.

## GitHub Review Behavior

When running in a GitHub-aware environment:

- Inspect unresolved review comments if the user asks to address review feedback.
- Inspect status checks when they influence confidence.
- Use Dependabot/code-scanning/secret-scanning only as supporting evidence, and only when available and authorized.
- Do not submit PR review comments unless the user explicitly asks.
- If asked to prepare comments, make each comment actionable, tied to a changed line when possible, and avoid exposing exploit details.

## Agent Workflow

1. Determine the PR, branch, or diff scope and base.
2. Read the full diff and PR description.
3. Identify security- and correctness-relevant changed flows.
4. Expand into surrounding context only where needed to prove reachability and control behavior.
5. Build the changed-flow threat model.
6. Check tests and relevant security tooling when available.
7. Run focused local tests or smoke tests for high-confidence findings when the repo provides a clear safe command.
8. Use temporary stubs only for unavailable external services, credentials, or nondeterministic dependencies, and clean them up before final output.
9. When subagents are available, ask an independent subagent to try to disprove each confirmed high or critical finding before reporting it.
10. Report net-new, newly exposed, or regression findings first.
11. Separate pre-existing risk and unverified concerns.
12. State coverage and residual risk clearly.

The best review is not the longest review. It is the one that most accurately explains whether the change creates new risk, why, and how to fix it.
