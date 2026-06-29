---
name: compliance-review
description: Maps codebase security controls to compliance frameworks (SOC 2, ISO 27001, NIST CSF, HIPAA, PCI-DSS) and identifies gaps and evidence issues. Use when preparing for an audit, assessing compliance posture, or mapping controls to framework requirements.
allowed-tools: Read Grep Glob Bash
---

# Compliance Review

Use this skill when the user needs a codebase-grounded compliance gap analysis. The goal is to map the security controls that are actually implemented in the code to the requirements of one or more compliance frameworks, then surface gaps, partial implementations, and missing evidence.

This is a defensive review. It does not produce exploit paths or audit-exploitation instructions. It maps what the code does, what it does not do, and what evidence an auditor would need.

## Core Principles

- Map from implemented controls to framework requirements, not the reverse. Do not assume a control exists because a framework requires it.
- Distinguish a present control from an enforced control. A logging library is imported; that does not mean security events are logged, retained, or reviewed.
- Judge evidence quality honestly. An auditor wants proof the control operates; the code must show enforcement, not just intent.
- Stay scope-aware. Not every framework requirement maps to code. Some are policy, physical, or organizational. Flag those as out-of-codebase scope rather than inventing findings.
- Report gaps, not vulnerabilities. A missing control is a compliance finding, not necessarily an exploitable bug.

## Scope Identification

First establish:

- Which framework or frameworks are in scope: SOC 2 (Trust Services Criteria), ISO 27001 (Annex A controls), NIST CSF (functions/categories), HIPAA (Security Rule safeguards), PCI-DSS (requirements). The user may specify one or several.
- The system boundary: which repo, service, or set of services is the subject of the audit. Controls outside this boundary are out of scope unless the user extends it.
- The data types handled: PII, PHI, cardholder data, customer tenant data, credentials. This determines which frameworks apply and which controls are in scope.
- The deployment model: SaaS, self-hosted, hybrid. This affects which physical, network, and vendor controls are code-reviewable.

Useful commands when available:

```sh
rg --files
rg -n "encrypt|cipher|aes|tls|ssl|cert|jwt|session|cookie|password|hash|bcrypt|argon2|secret|key|token|audit|log|rbac|role|permission|policy|rate.?limit|backup|retention|delete|purge|rotate"
rg -n "vendor|third.?party|subprocessor|integration|webhook|outbound|egress|allowlist|allow.?list"
```

## Framework Mapping

Map observable codebase controls to the in-scope framework requirements. Work framework by framework, control by control:

- For each requirement, determine whether a corresponding control is implemented in the code, partially implemented, or absent.
- Cite the file and line where the control is enforced (or should be). Evidence location matters for audit readiness.
- Note where a requirement is policy-only, physical-only, or organizational and therefore not verifiable from code. Mark those `not_applicable` with scope notes.

Common control-to-code mappings:

- Access control: auth middleware, role checks, tenant scoping, RBAC/ABAC enforcement, least-privilege service accounts, access reviews.
- Encryption: TLS config, at-rest encryption, key management, envelope encryption, cipher selection, cert rotation.
- Logging and monitoring: security event logging, audit trails, log integrity, alerting, anomaly detection, log retention config.
- Incident response: error handling, alerting hooks, on-call config, incident runbooks, severity classification in code or docs.
- Data retention and disposal: deletion jobs, TTL config, backup retention, purge scripts, archival logic.
- Vendor management: third-party dependency review, subprocessor config, outbound integration allowlists, secret scoping for integrations.
- Change management: branch protection, required reviews, CI gates, deployment approvals, rollback paths.
- Segregation of duties: deploy vs develop permissions, prod access restrictions, approval workflows, environment separation.
- Monitoring: uptime checks, dependency health, security scans, drift detection, configuration monitoring.

## Control Gap Analysis

For each framework requirement, classify the control state:

- Compliant: the control is implemented, enforced, and evidence is visible in the code or config.
- Partial: the control exists but is incomplete, inconsistent, or enforced in some paths but not others.
- Gap: the control is absent where the framework requires it.
- Needs evidence: the control may exist but the code does not clearly prove enforcement or operation.
- Not applicable: the requirement does not map to the codebase (policy, physical, organizational) or is out of the declared scope.

For partial and gap findings, trace the specific code path, config, or missing implementation. Do not report a gap generically; show where the control should be and is not.

## Evidence Assessment

For each control marked compliant or partial, assess evidence quality:

- Is the enforcement in code (not just a comment, doc, or intent statement)?
- Is the control applied consistently across all relevant paths, or only some?
- Is there a test, CI check, or config gate that proves the control continues to operate?
- Would an auditor be able to point to a file, config, or process artifact as proof?

Controls backed only by documentation, with no code or config evidence, should be downgraded to `needs_evidence` and flagged in the finding.

## Finding Standard

A compliance finding must answer:

- Which framework requirement or control is affected?
- What is the control state (gap, partial, needs_evidence)?
- Where in the code or config is the control missing, weak, or unprovable?
- What is the compliance and business impact (audit failure, condition, exception)?
- What evidence is currently available or missing?
- What minimal change would bring the control into compliance?
- What test or gate would prove ongoing compliance?

## Severity

Use severity based on compliance impact, not exploitability:

- Critical: a required control is entirely absent and would cause an audit failure or a reportable condition for a core requirement.
- High: a control is missing or non-functional for a requirement tied to sensitive data, access, or integrity.
- Medium: a control is partial, inconsistent, or lacking evidence for a requirement that would likely generate an auditor observation or recommendation.
- Low: a minor gap, documentation-only evidence, or a hardening issue unlikely to block compliance.
- Informational: a compliant control with a note for improvement, or an out-of-scope requirement recorded for completeness.

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `category` values such as `access-control`, `encryption`, `logging`, `incident-response`, `data-retention`, `vendor-management`, `change-management`, `segregation-of-duties`, `monitoring`, `training`, `policy`, `physical`, or `residual`.

Use `status` values: `compliant`, `gap`, `partial`, `not_applicable`, `needs_evidence`, or `no_confirmed_findings`.

Example row:

```csv
F-001,high,high,gap,logging,Security-relevant state changes lack audit logging,api/routes/findings.py:58,finding status transition endpoint,system,Status transitions that change finding severity or resolution are not logged with actor timestamp and before/after values,SOC 2 CC7.2 requires monitoring of system operations; auditor cannot evidence change accountability,No audit log write exists in the handler or its service layer; logger only records request metadata,Add structured audit log on every state change capturing actor id timestamp old and new state,Add test asserting an audit log row is written on status transition,SOC 2 CC7.2; reviewed finding routes and logging config
```

If no confirmed issues are found, still emit the header and one `no_confirmed_findings` informational row. Put coverage notes, framework-by-framework summaries, residual risk, and out-of-scope requirements after the CSV unless the user asks for CSV only.

## Validation

- Run local checks, grep patterns, config parsers, or test suites when they help confirm a control is enforced. Do not run destructive or production-affecting commands.
- Trace partial and gap findings to specific files and lines. A finding without a code location is weak evidence.
- Use temporary stubs only to isolate unavailable external services or credentials. Do not stub the control under review.
- Clean up scratch files, temporary configs, generated artifacts, and ad hoc scripts before reporting unless the user asked to keep them.
- When subagents are available, ask an independent subagent to challenge high-impact gap findings for whether an existing control, config, test, or process artifact was missed that would close the gap or upgrade the status.

## Rules

- Defensive only. Do not provide exploit chains, bypass instructions, or attack steps against the controls being reviewed.
- Map from code to framework, not framework to assumption. Every compliant, partial, or gap status needs a code or config citation.
- Do not invent controls. If a requirement is not satisfied in the code, report it as a gap or needs_evidence rather than assuming a policy exists elsewhere.
- Clearly separate code-verifiable controls from policy, physical, and organizational requirements. Mark the latter `not_applicable` with scope notes.
- Severity reflects compliance risk, not exploitability. Do not inflate a gap to critical because the underlying vulnerability class is severe unless the framework makes it a core requirement.
- Stay within the declared scope. Do not expand to repos, services, or environments the user did not include.
- If evidence is insufficient to determine control state, mark `needs_evidence` and state what is missing. Do not default to compliant when proof is absent.
