---
name: security-diff
description: Audits a branch or pull request diff for net-new security vulnerabilities, correctness bugs, breakage, feature-flag leaks, data exposure, devex regressions, and risky behavior changes. Use when reviewing BASE...HEAD or PR diffs before merge.
allowed-tools: Read Grep Glob Bash
---

# Security Diff

Use this skill for a strict diff-first audit of a branch, pull request, or patch. The goal is to find net-new security and correctness problems introduced by the diff, not to review the whole repository.

This skill is intentionally orthogonal to `code-quality`. This one asks: "Could this change break behavior, weaken security, leak data, or surprise users?"

## Ground Rules

- Review the diff first. Treat the diff as the primary evidence.
- Do not rabbit-hole into unrelated pre-existing code.
- Read surrounding code only when needed to prove reachability, understand contracts, or verify a changed behavior.
- Do not read PR comments, bugbot output, or prior review threads until after the independent audit is complete. Avoid anchoring.
- Report only issues that are introduced, exposed, or materially worsened by this diff.
- Separate pre-existing risks from diff-introduced findings.
- Do not modify code unless the user explicitly asks for fixes.

## Evidence Setup

Gather the same base evidence for every pass:

```sh
git status --short --branch
git diff --stat BASE...HEAD
git diff BASE...HEAD
```

If the base is unclear, infer it from upstream branch metadata, PR metadata, or the repository default branch. If ambiguity affects correctness, state the ambiguity before concluding.

Useful read-only PR commands when available:

```sh
gh pr view --json number,title,body,baseRefName,headRefName,author,files,commits,statusCheckRollup
gh pr diff
```

Do not approve, comment, push, or change PR state unless the user explicitly asks.

## Audit Checklist

Review every changed behavior that touches these areas:

### Security

- Authentication, sessions, tokens, cookies, SSO, OAuth, API keys, service accounts.
- Authorization, role checks, object ownership, admin boundaries, support access, tenant isolation.
- Secrets in code, logs, errors, telemetry, traces, client bundles, configs, examples, tests.
- SQL/NoSQL, shell, path, template, deserialization, XML/YAML, dynamic import, regex, parser, and URL-fetch sinks.
- SSRF, file upload, archive extraction, import/export, preview generation, crawlers, webhooks, and integrations.
- LLM or agentic flows where untrusted content can influence tools, retrieval, memory, shell, browser, network, or policy decisions.
- CI/CD, dependency, release, and environment changes that can affect production integrity.

### Correctness

- Broken API contracts, schema mismatches, migrations, serialization changes, backwards compatibility.
- Feature flags that leak unfinished behavior, bypass checks, or default to unsafe states.
- Error handling changes that hide failures, retry forever, drop work, or corrupt state.
- Race conditions, idempotency regressions, duplicate processing, ordering bugs, stale cache behavior.
- Timezone, pagination, filtering, sorting, null handling, enum, precision, and boundary bugs.
- Concurrency, async, queue, worker, cron, and transaction semantics.
- Performance or resource regressions that can trigger incidents or denial of service.

### Developer Experience And Operability

- Build, test, lint, migration, seed, local dev, or generated-code regressions.
- Logging and observability changes that make incidents harder to debug.
- Configuration defaults that make safe local or staging use harder.
- Error messages that mislead operators or users.

## Finding Standard

A finding must answer:

- What exact diff hunk introduced or exposed the issue?
- What changed behavior is affected?
- What security property, correctness contract, or operational invariant fails?
- What is the realistic impact?
- What evidence proves this is reachable or likely?
- What is the smallest fix?
- What test or check would prevent recurrence?

Do not report style issues. Put maintainability and boundary concerns in `code-quality`.

## Validation

- Run focused local tests, lint checks, build checks, migration checks, or smoke tests when they are clear, fast enough, and safe.
- Use temporary stubs or mock services only to isolate external providers, unavailable credentials, slow dependencies, or nondeterministic behavior. Do not stub out the changed contract or security control being reviewed.
- Remove temporary stubs, scratch files, local config changes, and ad hoc scripts before final output unless the user explicitly asked for test implementation.
- When subagents are available, ask an independent subagent to challenge confirmed high-impact findings for whether the diff really introduced the issue and whether the impact is overstated.

## Severity

- Critical: reliable security compromise, data loss/corruption, production outage, or irreversible business impact.
- High: auth bypass, privilege escalation, sensitive data exposure, major correctness regression, unsafe deploy path, or likely incident.
- Medium: scoped security exposure, important behavior break, fragile migration, meaningful operational regression, or incomplete safety control.
- Low: narrow bug, edge-case correctness issue, or minor operational regression.
- Informational: relevant observation without confirmed impact.

Use `confidence` separately: High, Medium, or Low.

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `net_new`, `newly_exposed`, `regression`, `pre_existing`, `needs_verification`, or `no_confirmed_findings`. Use `category` values such as `security`, `correctness`, `operability`, or `devex`.

Example row:

```csv
F-001,medium,high,regression,correctness,Migration drops nullable default used by old workers,db/migrations/20260603.sql:12,job creation flow,background worker,The diff makes status non-null without backfilling rows old workers create without status,Deploy can fail or drop queued work during rolling release,Migration changes constraint while worker code in base still inserts missing status,Backfill and deploy code that writes status before enforcing non-null,Add migration compatibility test or run old-worker insert against migrated schema,Reviewed BASE...HEAD migration and worker insert path
```

If no findings are found, still emit the header and one `no_confirmed_findings` informational row. Put pre-existing risks, needs-verification items, coverage, and residual risk after the CSV unless the user asks for CSV only.
