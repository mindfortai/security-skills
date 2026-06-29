---
name: finding-review
description: Triages cybersecurity findings for validity, exploitability, impact, and evidence quality. Use when reviewing vulnerability reports, scanner output, pentest findings, or bug bounty submissions.
allowed-tools: Read Grep Glob
---

# Finding Review

Use this skill to assess defensive cybersecurity findings. Prioritize evidence quality and reproducibility over generic severity labels.

## Workflow

1. Identify the claim, affected asset, affected user role, and security boundary.
2. Separate observed evidence from inference.
3. Determine whether the finding is valid, false positive, duplicate, informational, or under-evidenced.
4. Assess exploitability from the attacker's realistic starting permissions and network position.
5. Assess impact in business and technical terms.
6. Recommend the smallest remediation that removes the vulnerability class.

## Output Format

Output the triage result as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `valid`, `likely_valid`, `under_evidenced`, `duplicate`, `informational`, `likely_false_positive`, or `false_positive`. Use `category` values from the finding class, such as `authorization`, `authentication`, `injection`, `data-exposure`, `supply-chain`, `configuration`, `business-logic`, or `tests`.

For reviewed findings, use:

- `issue`: whether the original claim is supported and what security property would fail.
- `impact`: realistic technical and business impact if valid.
- `evidence`: observed evidence and whether it proves reachability.
- `fix`: smallest remediation for valid or likely-valid findings.
- `test`: safe validation or regression plan.
- `scope_notes`: missing evidence, duplicate reference, or false-positive rationale.

Put a short explanation, missing evidence, and validation notes after the CSV unless the user asks for CSV only.

## Rules

- Do not invent exploitability. If evidence is missing, say exactly what evidence is needed.
- Do not treat scanner labels as authoritative.
- Do not provide payloads, bypass chains, persistence guidance, or destructive exploitation steps.
- Prefer defensive validation steps that a system owner can run safely.
- When the target code or local test environment is available, run a safe smoke test or source-level validation before marking a finding `valid` or `false_positive`.
- Use temporary stubs only for unavailable external services, credentials, or nondeterministic dependencies. Do not stub the claimed vulnerable control or impacted path.
- Clean up temporary fixtures, scratch files, local config changes, and ad hoc validation scripts before final output.
- When subagents are available, ask an independent subagent to challenge high-impact verdicts for evidence quality, duplicate status, exploitability, and severity.
