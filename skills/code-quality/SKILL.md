---
name: code-quality
description: Audits a branch or pull request diff for harsh code quality, maintainability, boundary, complexity, testability, and architecture regressions. Use when reviewing BASE...HEAD or PR diffs for code health issues before merge.
allowed-tools: Read Grep Glob Bash
---

# Code Quality

Use this skill for a strict diff-first maintainability audit. The goal is to catch code quality regressions introduced by the branch before they become expensive to own.

This skill is intentionally orthogonal to `security-diff`. This one asks: "Will this change make the codebase harder to understand, test, change, operate, or safely extend?"

## Ground Rules

- Review the diff first.
- Do not turn this into a full repository architecture review.
- Read surrounding code only to understand local patterns, ownership boundaries, and whether the diff breaks them.
- Be direct and critical, but only report issues that are actionable.
- Do not report personal style preferences.
- Do not report issues that are pre-existing unless the diff worsens them.
- Do not modify code unless the user explicitly asks for fixes.

## Evidence Setup

Gather the diff evidence:

```sh
git status --short --branch
git diff --stat BASE...HEAD
git diff BASE...HEAD
```

Use PR metadata when available, but judge the actual diff rather than the PR description.

## Audit Checklist

### Size And Shape

- Files or functions that become too large to reason about.
- "1k-line file" pressure: newly large files, large functions, or large components that should be decomposed.
- Unfocused changes that mix unrelated concerns.
- Copy-pasted logic instead of a local abstraction.
- Abstractions added before there is real repeated complexity.

### Code Judo

Look for places where a smaller, simpler change would solve the problem:

- Replacing a narrow fix with a broad framework.
- Adding configuration or indirection where direct code would be clearer.
- Creating new concepts that duplicate existing project concepts.
- Solving one edge case by making every caller understand new complexity.
- Moving complexity to a worse layer instead of removing it.

### Boundaries And Architecture

- UI code reaching into persistence, infra, auth, or policy logic directly.
- Business logic leaking across layers.
- Shared modules taking dependencies on app-specific code.
- New circular dependencies or awkward import directions.
- Tenant, auth, billing, or security policies duplicated outside their owner.
- Background jobs, API handlers, and UI flows implementing divergent versions of the same rule.

### Readability And Maintainability

- Dense branching, boolean traps, unclear names, hidden side effects.
- State mutation that is hard to follow.
- Error handling that obscures the real failure.
- Comments that explain confusing code instead of simplifying the code.
- Magic constants, temporal coupling, or implicit ordering requirements.
- Public APIs whose names or types make misuse likely.

### Testability

- Logic that can only be tested through slow or flaky end-to-end paths.
- New code without seams for unit or integration testing where the repo expects them.
- Excessive mocking that hides the actual contract.
- Tests that assert implementation details instead of behavior.
- Missing regression tests for changed behavior.

### Operational Quality

- Logs that are noisy, misleading, or missing the identifiers needed to debug.
- Metrics, traces, or errors that lose critical context.
- Config changes that are hard to roll out or roll back.
- Migrations or release steps that require undocumented manual ordering.

## Finding Standard

A finding must answer:

- What exact diff change caused the maintainability issue?
- Which future maintenance task becomes harder?
- Which boundary, pattern, invariant, or testability property is degraded?
- Why this matters enough to block or change before merge?
- What smaller or cleaner alternative should be used?

Avoid vague findings like "this is messy." Name the concrete maintenance cost.

## Validation

- Run local tests, type checks, linters, builds, or focused smoke tests when they can confirm a claimed regression or boundary break safely.
- Use temporary stubs only to isolate unavailable external dependencies or slow services. Do not stub the contract, boundary, or behavior that the finding claims has regressed.
- Clean up scratch files, local config changes, temporary fixtures, and ad hoc scripts before final output unless the user asked for durable tests.
- When subagents are available, ask an independent subagent to challenge high-severity quality findings for whether the diff truly introduced the cost and whether the proposed better shape fits local patterns.

## Severity

- High: likely to cause recurring bugs, block future work, violate core architecture boundaries, or create long-lived ownership confusion.
- Medium: meaningful complexity, duplication, or testability regression that should be fixed before merge.
- Low: localized maintainability issue with clear cleanup path.
- Informational: useful note that should not block.

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `net_new`, `regression`, `pre_existing`, `needs_verification`, or `no_confirmed_findings`. Use `category` values such as `size`, `code-judo`, `boundary`, `readability`, `testability`, or `operability`.

Example row:

```csv
F-001,medium,high,net_new,boundary,Route duplicates billing policy outside service,api/routes/billing.py:96,billing plan update,tenant admin,The diff implements plan-change rules in the route instead of the billing policy service,Future billing changes must update two divergent policy paths and can create authorization drift,Existing billing routes call BillingPolicy but the new route bypasses it,Move plan-change decision into BillingPolicy and keep route as orchestration,Add route test that exercises BillingPolicy denial and allowed cases,Reviewed diff and adjacent billing routes
```

If no findings are found, still emit the header and one `no_confirmed_findings` informational row. Put pre-existing quality issues, coverage, and residual risk after the CSV unless the user asks for CSV only.
