---
name: branch-review
description: Orchestrates parallel security and code-quality audits for a branch or PR, deduplicates findings, and produces one prioritized merge-readiness list. Use when reviewing BASE...HEAD before merge.
allowed-tools: Read Grep Glob Bash
---

# Branch Review

Use this skill to run two independent branch audits and synthesize the results:

1. `pr-review`: security, correctness, breakage, feature flags, devex regressions.
2. `code-quality`: maintainability, boundaries, complexity, testability, architecture quality.

The output is one prioritized list for merge readiness.

## Core Idea

Gather `BASE...HEAD` evidence once. Give both audit passes identical diff evidence. Keep the passes independent. Deduplicate and prioritize the final findings. When both passes flag the same issue, rank it higher because overlap is signal.

## Ground Rules

- Diff-first only. Do not perform a full repo audit.
- Do not chase unrelated pre-existing issues.
- The security/correctness pass must complete its independent audit before reading PR comments, bugbot output, or prior review threads.
- The code-quality pass should focus on maintainability and boundaries, not security impact.
- The synthesis should preserve dissent: if one reviewer sees risk and the other does not, keep the evidence and confidence clear.
- Do not modify code unless the user explicitly asks for fixes.

## Evidence Setup

Identify base and head:

```sh
git status --short --branch
git branch --show-current
git merge-base HEAD origin/main
git diff --stat BASE...HEAD
git diff BASE...HEAD
```

If reviewing a PR and GitHub CLI is available:

```sh
gh pr view --json number,title,body,baseRefName,headRefName,author,files,commits,statusCheckRollup
gh pr diff
```

Use the same base/head and diff for both audit passes.

## Parallel Review Model

When the environment supports background agents or subagents:

- Start one reviewer with `pr-review`.
- Start one reviewer with `code-quality`.
- Provide both reviewers the same base/head, diff stat, full diff, and review scope.
- Instruct both reviewers not to read each other's work until they finish.

When the environment does not support background agents, run two isolated passes in sequence:

- Complete the full security/correctness pass first and write its findings.
- Then complete the full code-quality pass without revising the first pass.
- Only synthesize after both passes are complete.

## Synthesis Rules

Merge findings by changed behavior, not by file name.

For each finding, record:

- Source: security/correctness, code quality, or both.
- Severity from the originating pass.
- Confidence.
- Whether the same changed behavior was flagged by both passes.
- Whether tests or checks already cover the risk.
- Whether the finding is merge-blocking.

Priority ranking:

1. Critical or high security/correctness findings.
2. Findings flagged by both passes.
3. Medium security/correctness findings with high confidence.
4. High code-quality findings that affect core boundaries, future correctness, or testability.
5. Lower-confidence findings that need verification.
6. Non-blocking notes.

Do not average away severe findings. A critical security issue stays critical even if code quality is otherwise fine.

## Validation

- After independent passes, run focused local tests, builds, lint checks, migrations, or smoke tests for merge-blocking findings when commands are clear and safe.
- Use temporary stubs only to isolate unavailable external services, credentials, or nondeterministic dependencies. Do not stub the changed contract, security control, or boundary being reviewed.
- Clean up scratch files, temporary fixtures, mock servers, local config changes, and ad hoc scripts before final output unless the user asked for implemented tests.
- When subagents are available, use a separate validation subagent or ask the original reviewers to challenge each other's confirmed high-impact findings before synthesis.

## Output Format

Output the synthesized prioritized findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `merge_blocking`, `ready_after_fix`, `non_blocking`, `needs_verification`, `pre_existing`, or `no_confirmed_findings`. Use `category` values such as `security`, `correctness`, `code-quality`, `operability`, `devex`, or `both`.

Example row:

```csv
F-001,high,high,merge_blocking,both,New worker bypasses tenant-scoped service,workers/export_worker.py:44,export worker,tenant member,The branch queues exports through a worker that reads records by project_id without tenant binding,Tenant data can be exported across organizations and policy ownership is split across layers,Security pass found missing tenant check and quality pass found duplicated export logic,Route should enqueue actor and tenant context and worker should call the existing export service policy,Add cross-tenant export denial test covering route and worker,Source both; base origin/main head feature/export-worker
```

If no findings are found, still emit the header and one `no_confirmed_findings` informational row. Put reviewer summaries, deduplication notes, coverage, and merge readiness after the CSV unless the user asks for CSV only.
