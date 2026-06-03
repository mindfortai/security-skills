---
name: repo-review
description: Performs full defensive cybersecurity reviews of software repositories. Use when reviewing a repo, application, service, or codebase for security vulnerabilities, authorization flaws, insecure data flows, supply-chain risks, and missing security tests.
allowed-tools: Read Grep Glob Bash
---

# Repo Review

Use this skill when acting as a coding agent inside a repository. The goal is to find real, reachable security bugs and missing security controls, not to produce a generic checklist.

This skill is written for Claude Code, Codex, Cursor, and similar coding agents. Tool names vary by environment; use the local equivalents for file search, file reading, shell inspection, test execution, and Git diff inspection.

## Operating Principles

- Review from evidence. Do not assume architecture, trust boundaries, or framework behavior without checking the repo.
- Prefer exploitable paths over theoretical weakness. A finding needs a reachable path, affected asset, security boundary, and impact.
- Treat authorization, tenant isolation, identity, secret handling, and unsafe execution as first-class concerns.
- Keep the review defensive. Do not provide weaponized exploit chains, persistence steps, credential theft workflows, or instructions for attacking third-party systems.
- Do not change code unless the user explicitly asks for fixes. In review mode, report findings first.
- If evidence is missing, say what is missing and how to verify it.

## Review Setup

First establish the review frame:

1. Determine whether the user wants a full-repo review, diff review, or focused area review.
2. Identify the primary languages, frameworks, deployment model, package managers, and test commands from repo files.
3. Inspect `README`, architecture docs, route definitions, config files, Docker files, CI workflows, infra manifests, and auth-related code.
4. Check Git state before relying on file contents. If there are uncommitted changes, include them in scope unless the user says otherwise.
5. Avoid broad dependency installation or network calls unless they are already part of the repo workflow or the user approves them.

Useful discovery commands when available:

```sh
rg --files
git status --short
git diff --stat
git diff
```

## Attack Surface Map

Build a concise map before reporting findings:

- Entry points: HTTP routes, RPC handlers, GraphQL resolvers, webhooks, CLIs, workers, schedulers, queues, browser extension hooks, mobile/deep links, and admin tools.
- Trust boundaries: users, organizations, tenants, internal services, third-party APIs, files, environment variables, browser input, model output, and database records.
- Sensitive assets: credentials, API keys, tokens, sessions, PII, payments, customer data, tenant data, audit logs, model prompts, tool outputs, and infrastructure permissions.
- Security controls: authentication, authorization, input validation, output encoding, CSRF defenses, rate limits, audit logging, sandboxing, encryption, secret storage, and policy checks.

Do not publish the full map unless it helps the user. Use it to guide the review.

## Deep Review Areas

Prioritize areas where repository-specific evidence shows risk:

### Authentication and Sessions

- Login, signup, password reset, SSO, OAuth, magic links, API keys, service accounts, JWTs, refresh tokens, session cookies, device trust, logout, and account linking.
- Look for missing token binding, weak expiry, unsafe redirects, token leakage, insecure cookie flags, confused-deputy flows, and inconsistent auth middleware.

### Authorization and Tenant Isolation

- Object-level authorization before reads, writes, deletes, exports, billing actions, admin actions, and state transitions.
- Cross-tenant filters, organization membership checks, role checks, ownership checks, sharing links, invited users, impersonation, and background jobs.
- Watch for authorization in UI only, middleware bypasses, direct database access paths, batch endpoints, webhooks, and worker code that reuses user-controlled IDs.

### Injection and Unsafe Execution

- SQL, NoSQL, ORM raw queries, shell commands, template rendering, eval-like behavior, deserialization, expression languages, YAML/XML parsing, path handling, archive extraction, and dynamic imports.
- For LLM or agent systems, include prompt injection, tool input injection, untrusted model output driving privileged tools, and unsafe browser or shell automation.

### Data Exposure

- Logs, analytics, error reporting, telemetry, traces, cache keys, URLs, referrers, client bundles, local storage, exports, backups, and support tooling.
- Check whether secrets or tenant data can cross from privileged context to user-visible output.

### SSRF, Egress, and File Access

- URL fetchers, webhook testers, importers, preview generators, parsers, crawlers, storage integrations, PDF/image/video processors, and metadata endpoints.
- Check allowlists, DNS/IP validation, redirects, private network protections, file path normalization, symlink handling, and content-type assumptions.

### Supply Chain and Build Integrity

- Package manager lockfiles, install scripts, CI tokens, GitHub Actions permissions, Dockerfiles, generated code, vendored binaries, postinstall hooks, dependency pinning, release scripts, and deployment manifests.
- Report reachable supply-chain risk, not every outdated dependency.

### Cryptography and Secrets

- Key generation, random tokens, password hashing, encryption modes, signing, JWT verification, webhook signatures, secret rotation, local dev defaults, `.env` handling, and secrets in tests.
- Prefer proven libraries and framework primitives.

### Resilience and Abuse Controls

- Rate limits, quotas, file size limits, timeout handling, retry loops, idempotency, locking, queue poisoning, expensive queries, cache stampedes, and abuse-prone unauthenticated endpoints.

### Security Tests

- Identify whether tests cover the bug class. Missing tests are part of the finding when they make a regression likely.
- Prefer focused tests for the vulnerable path rather than broad snapshot tests.

## Finding Standard

Only report a finding when you can answer:

- What is the vulnerable code path?
- What trust boundary is crossed?
- What attacker capability is required?
- What security property fails?
- What data, permission, tenant, or system state is impacted?
- What minimal code or configuration change would fix it?
- What test would prevent regression?

If a concern is plausible but not proven, put it under `Needs Verification`, not `Findings`.

## Severity

Use severity based on reachable impact:

- Critical: reliable unauthorized access to highly sensitive data or privileged system control across users or tenants.
- High: unauthorized access or modification of sensitive data, auth bypass, privilege escalation, secret disclosure, or server-side code execution in a realistic path.
- Medium: scoped data exposure, partial authorization bypass, SSRF with limited reach, meaningful abuse, or security control bypass requiring constraints.
- Low: hardening issue with limited impact or requiring unlikely conditions.
- Informational: useful security observation without a demonstrated vulnerability.

Do not inflate severity because a vulnerability class sounds serious. Do not deflate severity because exploitation requires an authenticated low-privilege user.

## Output Format

Lead with a CSV findings list. Keep summaries secondary.

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `confirmed`, `needs_verification`, `pre_existing`, or `no_confirmed_findings`. Use `category` values such as `authorization`, `authentication`, `injection`, `ssrf`, `file-access`, `data-exposure`, `secrets`, `crypto`, `supply-chain`, `llm-agent`, `business-logic`, `abuse`, or `tests`.

Example row:

```csv
F-001,high,high,confirmed,authorization,Cross-tenant export lacks tenant filter,api/routes/exports.py:112,export job,tenant member,Export lookup uses user-controlled project_id without membership check,Tenant member can export another tenant's records,Route queues export before policy check and worker trusts queued project_id,Authorize project membership before queueing and re-check in worker,Add cross-tenant export denial test,Reviewed export route worker and tests
```

If no confirmed findings are found, still emit the header and one `no_confirmed_findings` informational row. Put needs-verification items, coverage, residual risk, commands run, and summary after the CSV unless the user asks for CSV only.

## Agent Workflow

1. Read repository structure and docs.
2. Identify frameworks and security-sensitive entry points.
3. Trace authentication and authorization paths before reviewing individual handlers.
4. Follow data from untrusted input to sensitive sinks.
5. Inspect tests for each confirmed or likely issue.
6. Run relevant local tests, static checks, or focused smoke tests when commands are clear and safe.
7. Use temporary stubs or mock services only to isolate unavailable external dependencies, credentials, or nondeterministic providers; never stub out the security control under review.
8. Clean up scratch files, throwaway fixtures, local config changes, temporary mock servers, and ad hoc scripts before reporting unless the user asked to keep them.
9. When subagents are available, ask an independent subagent to challenge confirmed high-impact findings for reachability, impact, severity, and missing controls before finalizing the CSV.
10. Report findings first, ordered by severity, with concrete file references.

When the repo is large, sample intelligently but explain coverage boundaries. Prefer following high-risk data flows end to end over scanning every file shallowly.
