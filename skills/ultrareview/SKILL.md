---
name: ultrareview
description: Performs a maximum-depth defensive security review for complex vulnerabilities using mandatory subagent planning, exhaustive todo-driven main-agent investigation, independent subagent validation, local smoke tests/stubs where safe, and final CSV findings only. Use for high-stakes appsec reviews where false positives must be rare and subtle multi-step bugs matter.
allowed-tools: Read Grep Glob Bash
---

# Ultrareview

Use this skill for the deepest security review mode. This is not a fast PR review, checklist audit, scanner triage, or generic best-practices pass. It is a high-effort defensive review intended to find complex, reachable vulnerabilities with an unusually high evidence bar.

The workflow is deliberately expensive:

1. A planning subagent builds a concrete investigation todo list.
2. The main agent works every todo to completion.
3. The main agent validates likely findings with code tracing, local tests, focused smoke tests, or temporary stubs when safe.
4. A validation subagent independently challenges the evidence, reachability, severity, and fixes.
5. The main agent reports only defensible findings in CSV.

If the environment cannot run subagents or background agents, do not claim to have performed an ultrareview. Say that subagents are unavailable and recommend `repo-review`, `pr-review`, or `security-diff` instead.

## Non-Negotiable Bar

- Findings must be real, reachable, and security-relevant.
- A finding needs a concrete entry point, attacker starting position, trust boundary, affected asset, failed control, evidence, minimal fix, and regression test.
- Do not report a vulnerability because a dangerous API, weak-looking pattern, or missing best-practice control exists. Prove the path.
- Do not rely on scanner labels, comments, TODOs, names, or intuition as proof.
- Do not inflate severity for dramatic vulnerability classes. Do not deflate severity because the attacker is an authenticated low-privilege user.
- Separate `needs_validation` from `confirmed`. The final CSV can include `needs_validation` rows only when the concern is important and the exact missing evidence is stated.
- Prefer one deep, confirmed complex vulnerability over ten shallow speculative rows.
- Do not provide exploit payload catalogs, persistence steps, credential theft workflows, or third-party attack instructions.

## Required Subagent Model

Ultrareview requires at least two subagent phases:

### Phase A: Planning Subagent

Spawn a read-heavy planning subagent before the main review begins.

Prompt shape:

```text
You are the ultrareview planning subagent. Do not report final findings.
Build a security investigation todo list for this repository, PR, branch, or scope.
Prioritize complex, realistic vulnerabilities and missed trust boundaries.
Return only:
1. Scope assumptions.
2. Attack surface map.
3. High-risk data/control flows.
4. A numbered todo list with owner area, files/searches to inspect, bug classes to prove or disprove, and suggested local validation.
5. Expected false-positive traps to avoid.
```

The planning subagent should be read-only unless the environment only supports broader inherited tools. It must not modify files.

The main agent must convert the subagent's todo list into tracked work and complete every item before final output. If a todo is impossible, mark it `blocked` with the exact missing evidence.

### Phase B: Validation Subagent

After the main agent has candidate findings, spawn a separate validation subagent.

Prompt shape:

```text
You are the ultrareview validation subagent. Your job is to disprove, downgrade, or sharpen the candidate findings.
For each candidate finding, check:
1. Is the entry point real?
2. Is the attacker starting position realistic?
3. Does untrusted input or authority cross the claimed trust boundary?
4. Does an existing control, policy, tenant filter, middleware, RLS rule, schema constraint, queue binding, approval gate, sandbox, or test already block the path?
5. Is the impact overstated?
6. Is the minimal fix sufficient?
7. Is the proposed regression test meaningful?
Return a verdict per candidate: accept, reject, downgrade, needs_validation, or merge_duplicate.
Include concise evidence for each verdict.
```

The main agent must incorporate validation results. Do not ship a finding rejected by the validation subagent unless the main agent can point to stronger evidence that the subagent missed. Record validation agreement, downgrade, or unresolved dissent in `scope_notes`.

## Main-Agent Workflow

### 1. Establish Review Frame

Identify:

- Scope: full repo, PR, branch diff, service, module, API, agent, deployment path, or product slice.
- Git state: branch, base/head, uncommitted changes, and whether generated or user changes are present.
- Primary languages, frameworks, package managers, runtime, deployment model, and test commands.
- Security-sensitive assets: credentials, sessions, API keys, PII, payments, tenant data, customer data, prompts, memories, tool outputs, source code, build artifacts, infrastructure permissions, audit logs, and admin actions.
- Actor model: anonymous, authenticated user, tenant member, owner, admin, support user, service account, integration, webhook sender, CI actor, internal operator, external content author, and compromised dependency.
- Trust boundaries: browser/server, tenant/tenant, user/admin, app/third party, app/database, app/worker, worker/infrastructure, model/tool, retrieved content/prompt, CI/deploy, build/runtime, and local config/production.

### 2. Complete The Planning Todo List

For every planning-subagent todo:

- Read the exact files and surrounding context needed to prove or disprove the bug class.
- Trace call chains from entry point to sink or state transition.
- Identify the control that should enforce the boundary.
- Inspect tests for the exact security property.
- Run targeted local validation when safe and clear.
- Mark the todo `done`, `blocked`, or `not_applicable`.

Do not skip inconvenient todos. Do not merge unrelated todos into a vague statement. If scope is too large, keep working by risk priority and explicitly record what remains unreviewed.

### 3. Deep Security Domains

Prioritize complex vulnerabilities that commonly evade shallow review.

#### Authorization And Tenant Isolation

- Object-level authorization on reads, writes, deletes, exports, search, counts, analytics, autocomplete, and state transitions.
- Tenant filters before data access, mutation, queueing, caching, exporting, or logging.
- Batch endpoints that authorize one object but operate on many.
- Admin/support/impersonation paths that cross customer boundaries.
- Service-account and API-key scope drift.
- Worker jobs, webhooks, scheduled tasks, and queues that trust user-controlled IDs.
- Sharing, invites, delegated admin, public links, and cross-org collaboration.
- Database RLS, ORM scopes, policy helpers, and direct SQL bypasses.

#### Authentication, Sessions, And Identity Binding

- SSO/OAuth/SAML/magic-link flows, state/nonce/redirect validation, account linking, invite acceptance, password reset, email change, MFA, refresh tokens, logout, session rotation, and revocation.
- Token audience, issuer, expiry, signing algorithm, key rotation, cookie flags, CSRF, CORS, and session fixation.
- Confused-deputy flows where third-party callbacks or integrations bind to the wrong tenant or actor.

#### Data Exposure And Cross-Context Leakage

- Sensitive fields in APIs, errors, logs, analytics, telemetry, traces, cache keys, URLs, referrers, browser storage, exports, generated reports, client bundles, object storage, backups, and support tooling.
- Cross-tenant leakage through search indexes, vector stores, memories, traces, cached summaries, notifications, or background job outputs.
- Debug or internal endpoints exposed through routing, feature flags, misordered middleware, or deployment config.

#### Injection, Unsafe Execution, And Parser Bugs

- SQL/NoSQL/ORM raw queries, shell commands, template rendering, path joins, archive extraction, deserialization, YAML/XML parsing, dynamic imports, eval-like behavior, expression languages, regex denial of service, unsafe URL construction, and file processing.
- Context-specific encoding failures: HTML, attribute, JavaScript, CSS, URL, SQL, shell, Markdown, CSV, PDF, email, and log contexts.
- Parser differentials, content-type confusion, extension/MIME mismatches, symlinks, zip slip, polyglot files, and decompression/resource limits.

#### SSRF, Egress, File, And Network Boundaries

- URL previewers, webhook testers, importers, crawlers, metadata fetchers, browser agents, integrations, PDF/image/video processors, storage clients, and internal HTTP clients.
- DNS rebinding, redirects, private IP ranges, localhost, cloud metadata, link-local services, internal admin panels, proxy behavior, credentialed requests, and egress allowlists.

#### LLM, Agent, MCP, Retrieval, And Memory Systems

- Untrusted webpages, emails, tickets, docs, logs, files, or tool results influencing privileged tools.
- Model output driving shell, browser, database, network, policy, admin, billing, deploy, or credential tools.
- Tool schemas that accept broad free-form authority instead of deriving actor, tenant, and resource from trusted context.
- MCP/resource exposure, cross-tenant retrieval, memory poisoning, trace leakage, prompt/tool-output leakage, approval replay, stale authority, and autonomous background actions after revocation.
- Prompt-only mitigations where source-of-truth policy should live in the tool or service.

#### Business Logic, Abuse, And Race Conditions

- Billing, quotas, trials, referrals, credits, approvals, role changes, exports, deletion, invitations, resets, marketplace flows, workflow state machines, idempotency, replay, ordering, TOCTOU, duplicate processing, and concurrency.
- Expensive unauthenticated operations, queue amplification, retry storms, cache stampedes, storage exhaustion, and missing per-user/per-tenant limits.

#### Supply Chain, CI/CD, And Deployment

- `pull_request_target`, `workflow_run`, broad workflow permissions, OIDC trust, deploy keys, release triggers, artifact provenance, generated code, install scripts, vendored binaries, postinstall hooks, unpinned actions/images, publish tokens, container hardening, IaC exposure, and branch protection.
- Reachable vulnerable dependencies in runtime or build-critical paths. Do not report every outdated dependency as a finding.

#### Cryptography And Secrets

- Password hashing, randomness, token generation, signing, encryption modes, nonce/IV use, JWT verification, webhook signatures, key management, rotation, secret storage, secret logging, local defaults, and test fixtures.
- Homegrown crypto or encoding where a standard library primitive should be used.

#### Tests, Observability, And Forensics

- Negative authorization tests, cross-tenant denial tests, forged callback tests, invalid token tests, replay/idempotency tests, unsafe input tests, egress tests, and sensitive-log redaction tests.
- Audit logs that prove who did what to which resource under which tenant and approval.
- Metrics and traces that help incident response without leaking secrets or customer data.

### 4. Local Validation

Where relevant and safe:

- Run existing targeted tests, type checks, linters, builds, migration checks, or local smoke tests.
- Use local dev servers, fixtures, fake tenants, fake users, fake documents, temporary queues, or mock services to prove a security property.
- Use stubs only for unavailable external services, credentials, nondeterministic providers, slow dependencies, or unsafe external effects.
- Never stub the security control under review: authorization, tenant filters, signature checks, replay protection, approval gates, sandboxing, validation, parsing, or policy enforcement must run for real.
- Clean up scratch files, throwaway tests, fake data, temp configs, mock servers, generated harnesses, local traces, and ad hoc scripts before final output unless the user explicitly asked to keep implemented tests.
- If validation is blocked, record the blocker and exact command, fixture, account, credential, service, or environment needed.

### 5. Candidate Finding Gate

Before sending a candidate to the validation subagent, the main agent must answer:

- What exact code path or configuration path is vulnerable?
- What exact actor can start the path?
- What exact trust boundary is crossed?
- What exact control is missing, late, weak, bypassed, or assumed?
- What sensitive asset, tenant, permission, money movement, system state, build artifact, or operational property is impacted?
- What existing controls were checked and why they do not block the path?
- What test coverage exists and why it is insufficient?
- What local validation was run or why it was blocked?
- What is the smallest durable fix?
- What regression test would fail before the fix and pass after?

If any answer is missing, the row is `needs_validation` or not reported.

## Severity

- `critical`: reliable cross-tenant compromise, privileged system control, server-side code execution, credential compromise with production blast radius, irreversible data loss/corruption, or release/deployment compromise.
- `high`: auth bypass, privilege escalation, significant sensitive data exposure, powerful SSRF/unsafe execution, exploitable CI/CD secret or artifact compromise, or major business logic abuse.
- `medium`: scoped data exposure, constrained authorization bypass, limited SSRF, meaningful abuse, replay/race issue under realistic constraints, or important security-control regression.
- `low`: narrow hardening issue with limited impact and realistic but low-probability exploitation.
- `informational`: useful security observation, test gap, or evidence limitation without demonstrated vulnerability.

Use `confidence` separately: `high`, `medium`, or `low`.

## Output Format

Final output must start with CSV using this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values:

- `confirmed`
- `needs_validation`
- `duplicate`
- `rejected_by_validation`
- `no_confirmed_findings`

Use `category` values such as:

- `authorization`
- `authentication`
- `tenant-isolation`
- `data-exposure`
- `injection`
- `ssrf-egress`
- `file-parser`
- `llm-agent`
- `business-logic`
- `race-replay`
- `abuse-resilience`
- `supply-chain`
- `ci-cd`
- `secrets-crypto`
- `tests-observability`

CSV rules:

- One row per final finding or material `needs_validation` concern.
- Quote fields containing commas, quotes, or newlines. Escape quotes by doubling them.
- `evidence` must include code/config facts and local validation result or validation blocker.
- `scope_notes` must include planning-subagent todo coverage and validation-subagent verdict.
- If there are no confirmed findings, still emit the header and one `no_confirmed_findings` informational row summarizing scope, validation, and residual risk.

After the CSV, include only these concise sections unless the user asks for CSV only:

```text
Todo Completion
- Done: ...
- Blocked: ...
- Not applicable: ...

Validation Summary
- Subagent accepted: ...
- Downgraded: ...
- Rejected: ...
- Needs validation: ...

Coverage
- Reviewed: ...
- Tests/checks run: ...
- Temporary validation artifacts cleaned up: yes | no, explain
- Not reviewed: ...
```

## Final Quality Checklist

Before final output:

- Every planning-subagent todo is marked done, blocked, or not applicable.
- Every confirmed finding survived validation-subagent challenge or has a documented reason the main agent overrode it.
- Every confirmed finding has concrete file/config references.
- Every confirmed finding includes local validation or an explicit blocker.
- Temporary validation artifacts are cleaned up.
- CSV is syntactically valid and uses the standard header.
- No exploit payload catalog or third-party attack instructions are included.
