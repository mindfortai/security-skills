---
name: pr-review
description: Reviews pull request diffs, builds focused threat models for changed behavior, and identifies net-new security vulnerabilities introduced or exposed by the PR. Use for detailed security reviews of PRs, branches, patches, or diffs.
allowed-tools: Read Grep Glob Bash
---

# PR Review

Use this skill when reviewing a pull request, branch, patch, or diff for security impact. The goal is to understand what behavior the PR changes, threat model that changed behavior, and report only net-new or newly exposed vulnerabilities.

This skill is written for Claude Code, Codex, Cursor, and similar coding agents. Tool names vary by environment; use local equivalents for Git inspection, file search, file reading, shell commands, and test execution.

## Core Principle

The diff is the starting point, not the whole review. A serious PR security review follows changed code outward until it understands the affected entry points, trust boundaries, data flows, permissions, and runtime behavior.

Report a finding only when the PR introduces, exposes, weakens, or makes reachable a security risk. If the PR touches existing vulnerable code but does not change its reachability or impact, call that out separately as pre-existing risk.

## Scope Rules

Classify each issue as one of:

- `Net-new`: introduced by the PR.
- `Newly exposed`: pre-existing risky code becomes reachable, privileged, externally accessible, or more impactful because of the PR.
- `Regression`: the PR removes, bypasses, or weakens an existing control.
- `Pre-existing`: relevant context, but not introduced or worsened by the PR.
- `Needs verification`: plausible PR-linked concern that lacks enough evidence.

Only `Net-new`, `Newly exposed`, and `Regression` belong in `Findings`. Put `Pre-existing` and `Needs verification` in separate sections.

## Setup And Diff Discovery

First determine the review target:

1. If a PR number or URL is provided, inspect PR metadata, changed files, commits, and diff.
2. If a branch is checked out, compare it to the appropriate base branch.
3. If only local changes exist, review staged and unstaged diffs.
4. If the base is ambiguous, identify likely base branches from Git metadata and ask only if ambiguity affects correctness.

Useful commands when available:

```sh
git status --short --branch
git diff --stat
git diff
git diff --cached
git merge-base HEAD origin/main
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
gh pr view --json number,title,body,baseRefName,headRefName,author,files,commits,reviews,statusCheckRollup
gh pr diff
```

Use read-only GitHub commands when authenticated and appropriate. Do not post comments, approve, request changes, push, or modify PR state unless the user explicitly asks.

## Phase 1: Understand The PR Intent

Before reviewing for vulnerabilities, summarize internally:

- What user-visible or system behavior changes?
- Which components, services, jobs, schemas, APIs, routes, policies, or workflows changed?
- What security boundaries does the PR touch?
- What sensitive assets or privileged operations does it affect?
- What tests were added, removed, or changed?
- What deployment, CI, infra, or dependency changes are included?
- Does the PR description match the actual diff?

Treat mismatch between PR stated intent and actual security-relevant behavior as a review signal.

## Phase 2: Build A Changed-Flow Threat Model

For each security-relevant changed flow, model:

- Entry point: route, handler, job, webhook, CLI, UI action, worker, queue event, scheduled task, migration, or build/deploy step.
- Actors: anonymous user, authenticated user, tenant member, admin, support user, service account, internal service, third-party provider, CI actor, or attacker.
- Trust boundary: browser to server, user to tenant, tenant to tenant, user to admin, app to third party, app to database, worker to infrastructure, model output to tool, CI to deployment.
- Sensitive assets: sessions, tokens, secrets, customer data, tenant data, payments, PII, logs, source code, prompts, model outputs, infra credentials, admin actions.
- Controls added, removed, changed, or assumed: authentication, authorization, tenant filters, validation, output encoding, CSRF, CORS, rate limits, audit logs, encryption, sandboxing, policy checks, tests.
- Failure modes: what happens if inputs are malicious, identities are low-privilege, tenants are different, third-party callbacks are forged, queues are replayed, or model outputs are hostile.

The threat model should be proportional to the PR. A small auth change may require deeper analysis than a large UI-only change.

## Phase 3: Expand Context Deliberately

Read surrounding code until you can prove or disprove reachability:

- Callers and callees of changed functions.
- Route registration and middleware order.
- Auth and authorization helpers.
- Schema/model relationships.
- Database queries and tenant filters.
- Feature flags and config defaults.
- Worker/event producers and consumers.
- Tests for changed behavior and security properties.
- Existing patterns in adjacent code.

Do not rewrite the whole repo review. Expand only where needed to answer whether the PR introduces a real security issue.

Useful search patterns:

```sh
rg -n "changedFunction|ChangedClass|routeName|permissionName|policyName"
rg -n "auth|session|token|tenant|org|role|permission|policy|admin|webhook|secret|encrypt|decrypt|jwt|oauth|csrf|cors|rate|limit"
rg -n "TODO|FIXME|SECURITY|unsafe|bypass|skip|allow|deny|public|internal"
```

## Phase 4: Security Review Domains

Review every domain touched by the PR. Be especially suspicious when the PR adds new entry points, broadens access, moves checks, changes schemas, adds integrations, changes default config, or changes CI/deploy behavior.

### Authentication And Sessions

Look for:

- New unauthenticated routes or callbacks.
- Login, signup, password reset, invitation, SSO, OAuth, SAML, magic-link, API-key, or service-account changes.
- Token parsing, verification, expiry, storage, rotation, revocation, cookie flags, redirect handling, and session fixation.
- Middleware order changes that can bypass auth.

### Authorization And Tenant Isolation

Look for:

- Object-level checks missing from new reads, writes, deletes, exports, and state transitions.
- Cross-tenant filters removed, weakened, or applied after data access.
- New batch endpoints, admin paths, support tooling, impersonation, sharing, or invite flows.
- Worker jobs or webhooks that trust user-controlled IDs.
- UI-only authorization assumptions.

### Data Exposure

Look for:

- New logs, traces, analytics, error messages, client responses, exports, cache keys, URLs, browser storage, or support tooling that include sensitive data.
- Server-only data moving into client bundles or public APIs.
- Debug endpoints, verbose errors, stack traces, or new metadata leaks.

### Injection And Unsafe Execution

Look for:

- Raw SQL/NoSQL, dynamic query construction, shell commands, template rendering, eval-like behavior, deserialization, XML/YAML parsing, dynamic imports, path joins, archive extraction, and regex denial-of-service.
- User-controlled input reaching dangerous sinks through new code paths.
- Sanitization that is context-insensitive or applied too late.

### SSRF, File, Parser, And Egress Risk

Look for:

- New URL fetchers, webhook testers, importers, crawlers, preview generators, file uploads, parsers, storage integrations, PDF/image/video processors, or metadata fetches.
- Missing redirect handling, private IP blocking, DNS rebinding protection, file path normalization, symlink checks, content-type validation, size limits, and timeouts.

### LLM And Agentic Systems

Look for:

- Untrusted prompt, webpage, file, email, ticket, or document content influencing privileged tools.
- Model output used as shell, browser, SQL, code, policy, or network instructions.
- Cross-tenant retrieval, memory, vector-store, prompt, trace, or tool-output leakage.
- Missing tool permission boundaries or human approval for sensitive actions.

### Business Logic And Abuse

Look for:

- Quota, billing, trial, referral, approval, reset, invite, role change, export, marketplace, workflow-state, or race-condition changes.
- New unauthenticated expensive operations or amplified background jobs.
- Idempotency and replay protection changes.

### Supply Chain, CI, And Deployment

Look for:

- New dependencies, install scripts, GitHub Actions permissions, secrets exposure, build steps, release automation, Dockerfile changes, generated code, artifact publishing, and environment default changes.
- Whether dependency changes introduce known security alerts when tooling is available.

### Cryptography And Secrets

Look for:

- Randomness, password hashing, signing, encryption, JWT verification, webhook signatures, key management, config defaults, secret storage, and test fixtures.
- Secret values or credentials added to code, logs, docs, tests, or examples.

### Tests And Regression Coverage

Look for tests that prove:

- Low-privilege users cannot perform privileged actions.
- Tenant A cannot access tenant B.
- Unauthenticated callers are rejected.
- Invalid tokens and forged callbacks fail.
- Malicious input is rejected or safely encoded.
- Sensitive data is not logged or returned.
- Limits, timeouts, and replay/idempotency protections hold.

Missing security tests are not automatically a vulnerability, but they lower confidence and can be a finding when the PR changes a high-risk control.

## Finding Standard

A finding must answer:

- What exact PR change introduced or exposed the risk?
- What changed flow is affected?
- What attacker starting position is realistic?
- What trust boundary is crossed?
- What control is missing, weakened, removed, or bypassed?
- What sensitive asset, permission, tenant, operation, or system state is impacted?
- Why existing code or tests do not already prevent it?
- What minimal fix would close the issue?
- What regression test should be added?

Do not report generic best practices. Do not report vulnerabilities solely because a dangerous-looking API exists. Prove the path from PR change to security impact.

## Severity

Rate based on reachable delta introduced by the PR:

- Critical: PR creates reliable unauthorized access to highly sensitive data, cross-tenant compromise, privileged system control, or server-side code execution.
- High: PR creates auth bypass, privilege escalation, sensitive data disclosure, significant tenant isolation failure, secret exposure, or powerful SSRF/unsafe execution.
- Medium: PR creates scoped data exposure, partial authorization bypass, meaningful abuse, SSRF with limited reach, weak security control change, or high-risk missing validation under constraints.
- Low: PR creates limited hardening issue with narrow impact or unlikely exploitation.
- Informational: relevant observation without confirmed vulnerability.

Include confidence separately: High, Medium, or Low.

## Output Format

Lead with a CSV findings list. Keep the changed-flow threat model concise and secondary.

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `net_new`, `newly_exposed`, `regression`, `pre_existing`, `needs_verification`, or `no_confirmed_findings`. Use `category` values such as `authorization`, `authentication`, `data-exposure`, `injection`, `ssrf`, `secrets`, `supply-chain`, `llm-agent`, `business-logic`, `abuse`, or `tests`.

Example row:

```csv
F-001,high,high,net_new,authorization,New batch update trusts request tenant id,api/routes/projects.py:74,batch project update,tenant member,The PR adds batch updates keyed by tenant_id from the request body without per-project membership checks,Tenant member can modify projects outside their tenant,Diff adds tenant_id body field and service updates all matching ids before policy enforcement,Derive tenant from authenticated actor and authorize each project id,Add cross-tenant batch update denial test,Base origin/main head feature/batch-update
```

If no PR-introduced vulnerabilities are found, still emit the header and one `no_confirmed_findings` informational row. Put the changed-flow threat model, pre-existing risks, needs-verification items, coverage, and residual risk after the CSV unless the user asks for CSV only.

## GitHub Review Behavior

When running in a GitHub-aware environment:

- Inspect unresolved review comments if the user asks to address review feedback.
- Inspect status checks when they influence security confidence.
- Use Dependabot/code-scanning/secret-scanning only as supporting evidence, and only when available and authorized.
- Do not submit PR review comments unless the user explicitly asks.
- If asked to prepare comments, make each comment actionable, tied to a changed line when possible, and avoid exposing exploit details.

## Agent Workflow

1. Determine the PR, branch, or diff scope.
2. Read the full diff and PR description.
3. Identify security-relevant changed flows.
4. Expand into surrounding context only where needed to prove reachability and control behavior.
5. Build the changed-flow threat model.
6. Check tests and relevant security tooling when available.
7. Run focused local tests or smoke tests for high-confidence findings when the repo provides a clear safe command.
8. Use temporary stubs only for unavailable external services, credentials, or nondeterministic dependencies, and clean them up before final output.
9. When subagents are available, ask an independent subagent to try to disprove each confirmed high or critical PR-linked finding before reporting it.
10. Report net-new, newly exposed, or regression findings first.
11. Separate pre-existing risk and unverified concerns.
12. State coverage and residual risk clearly.

The best review is not the longest review. It is the one that most accurately explains whether the PR creates new risk, why, and how to fix it.
