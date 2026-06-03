---
name: code-review
description: Reviews source code for security bugs, authorization gaps, injection risks, unsafe secret handling, insecure defaults, and missing tests. Use when reviewing code, pull requests, diffs, or implementation plans.
allowed-tools: Read Grep Glob
---

# Code Review

Use this skill for defensive source-code review. Lead with concrete findings tied to files, functions, routes, or data flows.

## Review Order

1. Map entry points: routes, handlers, jobs, CLIs, webhooks, and background workers.
2. Trace trust boundaries: user input, external services, files, environment variables, and database records.
3. Check authorization before sensitive reads, writes, state transitions, or tenant-scoped access.
4. Check injection surfaces: SQL, shell, template rendering, SSRF, path traversal, deserialization, and unsafe eval.
5. Check secret handling: logging, persistence, transport, client exposure, and default credentials.
6. Check whether tests would catch the bug class.

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `category` values such as `authorization`, `authentication`, `injection`, `ssrf`, `file-access`, `data-exposure`, `secrets`, `crypto`, `llm-agent`, `business-logic`, or `tests`.

If no confirmed issues are found, still emit the header and one `no_confirmed_findings` informational row. Put open questions, residual risk, and test gaps after the CSV unless the user asks for CSV only.

## Rules

- Cite concrete code locations when possible.
- Do not report theoretical issues without an executable path.
- Do not suggest broad rewrites when a narrow authorization, validation, or encoding fix solves the issue.
- Do not include offensive payload catalogs or instructions for attacking third-party systems.
- When a finding is locally testable, run the narrowest safe smoke test or existing test command before reporting it.
- Use temporary stubs only to isolate unavailable external dependencies, credentials, or nondeterministic services. Do not stub the vulnerable path or security control being reviewed.
- Clean up scratch files, temporary fixtures, mock servers, config changes, and ad hoc scripts before final output unless the user asked for durable tests.
- When subagents are available, ask an independent subagent to challenge confirmed high-impact findings for reachability, severity, and whether existing controls already block the path.
