---
name: threat-model
description: Builds a deep understanding of an entire codebase, then produces a professional red-team application security threat model as a standalone HTML report. Use when mapping architecture, data flows, trust boundaries, attack surface, and realistic abuse cases.
allowed-tools: Read Grep Glob Bash Write
---

# Threat Model

Use this skill when the user wants a full application-security threat model of a repository, delivered as a polished standalone HTML page.

This is not a checklist exercise. The agent must first understand how the system works, then model how it can fail under realistic adversarial pressure. The output should help engineers and security reviewers make decisions.

This skill is written for Claude Code, Codex, Cursor, and similar coding agents. Tool names vary by environment; use the local equivalents for file search, file reading, command execution, and writing the final report.

## Deliverable

Produce a standalone HTML report, preferably named:

```text
appsec-threat-model.html
```

Use `templates/threat-model-report.html` from this skill as the visual and structural template when available. If the environment cannot directly read skill template files, recreate the same structure from the required report sections below.

The final report must be self-contained:

- Inline CSS only.
- No external JavaScript, fonts, images, trackers, or CDN assets.
- No hidden dependencies on local build tooling.
- Clean typography, clear hierarchy, readable tables, and printable layout.

## Operating Principles

- Understand before judging. Do not write the threat model until the architecture, trust boundaries, entry points, and sensitive data flows are grounded in repository evidence.
- Prefer system-specific threat scenarios over generic STRIDE filler.
- Model realistic attacker paths without providing weaponized exploit instructions, payload catalogs, persistence steps, credential theft workflows, or third-party attack guidance.
- Tie every important claim to code, config, docs, tests, or explicit uncertainty.
- Separate confirmed design facts from inferred behavior and unknowns.
- Treat missing security boundaries, missing tests, and unclear ownership as reportable risks when they materially affect security.

## Phase 1: Repository Comprehension

Build a codebase map before threat modeling.

Inspect, when present:

- `README`, architecture docs, API docs, runbooks, deployment docs, ADRs, and diagrams.
- Package manifests, lockfiles, workspace files, monorepo config, and build scripts.
- Route definitions, controllers, handlers, RPC services, GraphQL resolvers, workers, CLIs, cron jobs, webhooks, and event consumers.
- Auth, session, identity, tenant, role, permission, policy, and middleware code.
- Database schema, migrations, ORM models, storage clients, queues, caches, search indexes, and external integrations.
- Infrastructure-as-code, Dockerfiles, compose files, Kubernetes manifests, Terraform, CI/CD workflows, release scripts, and secrets/config examples.
- Tests around authentication, authorization, validation, tenancy, and critical workflows.

Useful discovery commands when available:

```sh
rg --files
git status --short
find . -maxdepth 3 -type f
rg -n "auth|session|token|tenant|org|role|permission|policy|admin|webhook|secret|encrypt|decrypt|jwt|oauth|saml|csrf|cors|rate|limit"
```

Do not run dependency installation, migrations, destructive commands, production network calls, or broad scanners unless the user explicitly approves them or the repo workflow clearly permits them.

## Phase 2: Build The System Model

Create an internal working model with these elements:

- Product purpose: what the application exists to do.
- System shape: frontend, backend, jobs, agents, data stores, third-party services, deployment boundaries, and operational surfaces.
- Actors: anonymous users, authenticated users, admins, support users, service accounts, internal services, external providers, CI/CD actors, and attackers.
- Sensitive assets: credentials, sessions, API keys, tokens, PII, payment data, customer data, tenant data, prompts, model outputs, audit logs, source code, infrastructure credentials, and administrative controls.
- Entry points: routes, APIs, webhooks, file uploads, importers, parsers, URL fetchers, background workers, queues, CLIs, browser surfaces, extensions, model/tool interfaces, and admin panels.
- Trust boundaries: browser to server, tenant to tenant, user to admin, app to third party, app to database, app to worker, worker to infrastructure, model output to tool execution, CI to deployment, and local config to runtime.
- Data flows: how sensitive data enters, moves, transforms, leaves, and is logged or cached.
- Security controls: authentication, authorization, validation, output encoding, CSRF, CORS, rate limits, audit logging, encryption, secret storage, sandboxing, network controls, and test coverage.

If the system is too large to understand exhaustively in one pass, prioritize high-risk flows and explicitly list coverage limits.

## Phase 3: Red-Team AppSec Threat Modeling

Use repository-specific evidence to identify plausible abuse cases and threat scenarios.

Analyze at least these domains when applicable:

- Authentication and account lifecycle: signup, login, logout, password reset, SSO, OAuth/SAML, magic links, invitation flows, account linking, API keys, service accounts, and token rotation.
- Authorization and tenant isolation: object-level access, role checks, organization membership, admin boundaries, support access, sharing, exports, bulk operations, background jobs, and indirect object references.
- Data exposure: logs, telemetry, traces, error messages, analytics, browser storage, caches, exports, generated files, object storage, client bundles, and support tools.
- Unsafe input handling: SQL/NoSQL injection, shell invocation, template injection, path traversal, archive extraction, deserialization, XML/YAML parsing, SSRF, URL previewers, file uploads, and content processing.
- Agentic or LLM surfaces: prompt injection, untrusted model output controlling tools, tool permission boundaries, browser automation, retrieval poisoning, memory poisoning, and cross-tenant context leakage.
- Business logic abuse: workflow state changes, billing, quotas, trials, referrals, approvals, invitations, reset flows, marketplace/actions, and race conditions.
- Supply chain and deployment: package scripts, CI permissions, release workflows, container hardening, dependency pinning, generated code, secrets in build logs, artifact provenance, and environment separation.
- Resilience and abuse prevention: rate limits, timeout behavior, retry loops, idempotency, queue poisoning, expensive operations, storage exhaustion, and unauthenticated resource consumption.
- Cryptography and secrets: password hashing, randomness, signing, encryption, key management, webhook signatures, JWT verification, config defaults, and local development secrets.

## Threat Scenario Standard

Each meaningful threat scenario should include:

- Scenario title.
- Affected component or flow.
- Attacker starting position.
- Preconditions.
- Trust boundary crossed.
- Attack narrative at a safe, non-weaponized level.
- Impact.
- Existing controls observed in the repo.
- Gaps or weak assumptions.
- Recommended mitigations.
- Validation approach.
- Residual risk after mitigation.

Do not include step-by-step exploitation instructions or payloads. The purpose is to help defenders fix design and implementation risk.

## Risk Rating

Rate risks using likelihood, impact, and confidence:

- Likelihood: Low, Medium, High.
- Impact: Low, Medium, High, Critical.
- Confidence: Low, Medium, High.
- Priority: P0, P1, P2, P3.

Use evidence to justify ratings. Keep `confidence` low when code paths, deployment controls, or production assumptions are unclear.

## Findings CSV

The report's risk register and any chat summary of risks must use this exact CSV header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `confirmed`, `likely`, `needs_validation`, `design_risk`, `accepted_control`, or `no_confirmed_findings`. Use `category` values such as `authorization`, `authentication`, `data-exposure`, `injection`, `ssrf`, `file-access`, `llm-agent`, `business-logic`, `supply-chain`, `resilience`, `crypto`, or `tests`.

For threat scenarios, use:

- `location`: primary code, config, report section, or component reference.
- `asset_or_flow`: sensitive asset, trust boundary, or data flow.
- `actor`: realistic attacker starting position.
- `issue`: threat scenario and failed security property.
- `impact`: likely customer, tenant, data, operational, or business consequence.
- `evidence`: repo facts, inferred architecture, or explicit missing evidence.
- `fix`: recommended mitigation.
- `test`: validation plan or regression test.
- `scope_notes`: priority, likelihood, residual risk, or coverage limit.

If no confirmed risks are found, still emit the header and one `no_confirmed_findings` informational row in the risk register.

## Required HTML Report Structure

The report must include:

1. Title block with repo name, date, reviewer/agent, scope, and commit or branch when available.
2. Executive summary.
3. Scope and methodology.
4. System overview.
5. Architecture inventory.
6. Trust boundaries.
7. Sensitive assets.
8. Entry points and attack surface.
9. Data-flow summary.
10. Threat scenarios.
11. Risk register as a CSV-formatted table using the standard findings header.
12. Security controls observed.
13. Gaps and recommended roadmap.
14. Validation plan.
15. Review coverage and limitations.
16. Appendix with key files reviewed and commands run.

Use tables for inventories and risk registers. Use compact visual blocks for severity and priority. Use code path references for evidence.

## Evidence Rules

- Link or reference concrete files and functions using repo-relative paths.
- For claims based on config or tests, name the relevant file.
- For inferred architecture, mark it as inferred.
- For unknown production behavior, mark it as unknown and explain what evidence would resolve it.
- Do not hide uncertainty inside confident prose.
- Where locally testable, run focused smoke tests, existing tests, static checks, or local harnesses to validate high-priority risks before placing them in the risk register.
- Use temporary stubs only to isolate unavailable external services, credentials, nondeterministic providers, or slow dependencies. Do not stub the trust boundary, policy, approval gate, tenant filter, or parser behavior being modeled.
- Clean up scratch files, temporary fixtures, mock servers, local config changes, generated harnesses, and ad hoc scripts before finalizing the report unless the user asked for durable tests.
- When subagents are available, ask an independent subagent to challenge high or critical threat scenarios for reachability, impact, confidence, and whether observed controls already mitigate them.

## Output Quality Bar

Before finalizing the HTML:

- Open or inspect the file enough to verify it is valid HTML with one `<!doctype html>`, one `<html>`, and balanced major sections.
- Ensure the report is readable without external assets.
- Ensure no placeholder text remains.
- Ensure every high or critical risk has a recommended mitigation and validation plan.
- Ensure the appendix lists commands run and files reviewed.
- Ensure the report does not contain unsafe exploitation instructions.

## Agent Workflow

1. Confirm scope if the user has not provided one and the repo is ambiguous.
2. Discover the repo structure and Git state.
3. Build the system model from code, docs, config, and tests.
4. Identify trust boundaries, assets, entry points, and data flows.
5. Threat model high-risk flows deeply.
6. Draft the report using the HTML template.
7. Validate the HTML artifact for completeness and readability.
8. Report the output path and summarize the top risks in chat.

If the user asks only for the artifact, keep the chat response brief and point to the generated HTML file.
