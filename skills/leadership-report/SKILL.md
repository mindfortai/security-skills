---
name: leadership-report
description: Produces an executive security posture report for non-technical leaders by analyzing a target application or repository with deep appsec rigor. Use when creating board-ready, founder-facing, or customer-facing security reports.
allowed-tools: Read Grep Glob Bash Write
---

# Leadership Report

Use this skill when the user wants a decision-ready security posture report for executives, founders, board members, customers, auditors, or non-technical stakeholders.

The analysis must be rigorous, but the report must be understandable. The agent should investigate like an application-security reviewer, then communicate like a clear executive advisor.

This skill is written for Claude Code, Codex, Cursor, and similar coding agents. Tool names vary by environment; use local equivalents for file search, file reading, shell inspection, Git/GitHub inspection, security-tool output review, and report writing.

## Deliverable

Produce a standalone HTML report, preferably named:

```text
leadership-report.html
```

Use `templates/leadership-report.html` from this skill as the visual and structural template when available. If the environment cannot directly read skill template files, recreate the same structure from the required report sections below.

The final report must be:

- Written for non-technical executives.
- Self-contained with inline CSS only.
- Clear about confidence, scope, and limitations.
- Specific enough for engineering and security leaders to act on.
- Free of exploit payloads, attack recipes, or unnecessary implementation detail.

## Operating Principles

- Do the deep work before simplifying. Executive clarity must be earned from evidence, not guessed.
- Translate technical risk into business risk: customer trust, revenue, uptime, compliance, data exposure, operational resilience, and deal friction.
- Distinguish confirmed issues from likely risks and unavailable evidence.
- Do not treat scanner output as truth. Validate whether findings are relevant to the product, reachable in runtime, exploitable, or blocked by existing controls.
- When Dependabot or security-tooling data is unavailable, say it is unavailable. Do not report "no findings" unless the source was actually checked.
- Avoid jargon unless it is essential, and define it in plain language.

## Phase 1: Establish Scope

Determine whether the target is:

- A single repository.
- A product spanning multiple repositories.
- A deployed application.
- An organization or engineering portfolio.
- A release, pull request, or security program snapshot.

Record:

- Target name.
- Date.
- Reviewer or agent.
- Branch, commit, release, or time window.
- Repositories and systems in scope.
- Explicitly excluded systems.
- Evidence sources available and unavailable.

## Phase 2: Understand The Product Or Organization

Build enough product context to explain security posture in business terms.

Inspect, when available:

- README, product docs, architecture docs, API docs, runbooks, deployment docs, ADRs, and diagrams.
- Package manifests, lockfiles, workspace files, build scripts, and release scripts.
- Route definitions, controllers, handlers, RPC services, GraphQL resolvers, background workers, CLIs, cron jobs, webhooks, queues, and event consumers.
- Authentication, session, identity, tenant, role, permission, policy, support-access, and admin code.
- Database schema, migrations, ORM models, storage clients, queues, caches, search indexes, and external integrations.
- Infrastructure-as-code, Dockerfiles, compose files, Kubernetes manifests, Terraform, CI/CD workflows, environment examples, and secret/config handling.
- Tests around authentication, authorization, tenancy, validation, security controls, and critical workflows.

Useful repository discovery commands when available:

```sh
rg --files
git status --short
git remote -v
git branch --show-current
git rev-parse --short HEAD
rg -n "auth|session|token|tenant|org|role|permission|policy|admin|webhook|secret|encrypt|decrypt|jwt|oauth|saml|csrf|cors|rate|limit"
```

Do not run dependency installation, migrations, destructive commands, production network calls, or broad scanners unless the user explicitly approves them or the repo workflow clearly permits them.

## Phase 3: AppSec Posture Analysis

Analyze the target with the rigor of a professional appsec review, but plan to summarize for executives.

Cover these domains when applicable:

- Product criticality: what the system protects, who depends on it, and what failure would mean.
- Authentication and account lifecycle.
- Authorization, roles, admin boundaries, support access, and tenant isolation.
- Sensitive data handling, logging, exports, analytics, telemetry, and browser exposure.
- Input handling: injection, SSRF, file upload, parser, deserialization, template, shell, path, and unsafe execution surfaces.
- Agentic or LLM-specific risk: prompt injection, tool permission boundaries, retrieval or memory poisoning, cross-tenant context leakage, and model-output-to-action paths.
- Business logic abuse: workflow state changes, billing, quotas, trials, invitations, approvals, resets, race conditions, and abuse-prone unauthenticated flows.
- Supply chain and build integrity.
- Cloud, infrastructure, deployment, and CI/CD exposure.
- Secrets and cryptography.
- Abuse prevention, rate limiting, resilience, and operational monitoring.
- Security test coverage and regression risk.

## Phase 4: Dependabot And Security Tooling

Use available security tooling as evidence, not as a substitute for judgment.

Check for these sources when available:

- GitHub Dependabot alerts.
- GitHub code scanning alerts, CodeQL, SARIF files, and security tab exports.
- Secret scanning alerts or local secret-scan reports.
- Package manager audit output: `npm audit`, `pnpm audit`, `yarn npm audit`, `pip-audit`, `safety`, `cargo audit`, `bundler-audit`, `govulncheck`, `osv-scanner`, and similar.
- Container and infrastructure scans: Trivy, Grype, Docker Scout, Checkov, tfsec, Terrascan, kube-score, kube-linter.
- SAST and policy tools: Semgrep, SonarQube, Snyk, Bearer, Brakeman, Bandit, ESLint security plugins, Gosec.
- DAST or pentest outputs: Burp, ZAP, MindFort, bug bounty reports, customer security reviews, and internal assessment reports.
- CI results, release gates, branch protection, required checks, and workflow permissions.

If the repository is hosted on GitHub and `gh` is authenticated, useful read-only checks include:

```sh
gh repo view --json nameWithOwner,isPrivate,defaultBranchRef,url
gh api repos/{owner}/{repo}/dependabot/alerts --paginate
gh api repos/{owner}/{repo}/code-scanning/alerts --paginate
gh api repos/{owner}/{repo}/secret-scanning/alerts --paginate
```

Only run these if the command is appropriate for the user's environment and authorization. If access is denied or the feature is disabled, record that as an evidence limitation rather than a clean bill of health.

When reviewing tool findings:

- Group duplicates into themes.
- Highlight reachable or business-relevant risks.
- De-emphasize findings that are dev-only, unreachable, blocked by controls, or already patched.
- Preserve critical findings even if they are not easy to explain, but translate them into plain language.
- Include vulnerability counts only when the source and time window are clear.

## Executive Risk Rating

Use a simple posture rating:

- Strong: material controls are in place, evidence is current, and no high-risk unresolved issues are known.
- Adequate: core controls exist, but some gaps or validation limits remain.
- Needs Attention: one or more important risks need near-term executive support.
- High Risk: credible risk to sensitive data, customers, revenue, production operations, or compliance requires urgent action.
- Unknown: evidence is too incomplete to responsibly rate posture.

Also assign:

- Business impact: Low, Moderate, Significant, Severe.
- Urgency: Immediate, 30 days, 60-90 days, Monitor.
- Confidence: Low, Medium, High.

Keep confidence low when live configuration, security-tool outputs, or production deployment evidence is missing.

## Findings CSV

The report's technical appendix and any chat summary of risks must use this exact CSV header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `confirmed`, `likely`, `needs_validation`, `tooling_gap`, `accepted_control`, or `no_confirmed_findings`. Use `category` values such as `authorization`, `authentication`, `data-exposure`, `supply-chain`, `ci-cd`, `secrets`, `infrastructure`, `llm-agent`, `business-logic`, `resilience`, `tests`, or `tooling`.

For executive reports, keep CSV rows concise and business-readable:

- `issue`: what security or evidence gap exists.
- `impact`: customer trust, data, uptime, compliance, revenue, operational, or deal impact.
- `evidence`: code path, config, test, alert source, scanner output, or explicit missing evidence.
- `fix`: executive-actionable remediation.
- `test`: validation, control, metric, or security check that proves completion.
- `scope_notes`: owner type, urgency, time window, or evidence limitation.

If no confirmed risks are found, still emit the header and one `no_confirmed_findings` informational row in the appendix.

## Required HTML Report Structure

The report must include:

1. Title block with target, date, scope, revision or time window, and reviewer.
2. One-page executive summary.
3. Overall security posture rating.
4. Top business risks.
5. What is working well.
6. Key gaps and why they matter.
7. Dependabot and security-tooling summary.
8. Product and architecture context.
9. Customer, data, compliance, and operational impact.
10. Recommended executive actions.
11. 30/60/90-day security roadmap.
12. Metrics and evidence table.
13. Technical findings appendix as a CSV-formatted table using the standard findings header.
14. Confidence, limitations, and open questions.
15. Appendix with technical evidence sources, commands run, and reviewed files.

Do not overload executives with raw vulnerability lists. Put detail in appendix tables and summarize themes in the main body.

## Writing Style

Use plain language:

- Prefer "customer data could be exposed" over "confidentiality impact."
- Prefer "one customer may be able to access another customer's records" over "tenant isolation failure."
- Prefer "attackers could abuse this endpoint to run expensive work" over "resource exhaustion vector."
- Prefer "we could not verify" over "unknown unknowns."

Avoid:

- Acronym-heavy prose.
- Long lists of CVEs without business context.
- Fear-based language.
- Unsupported certainty.
- Detailed exploitation instructions.

## Evidence Rules

- Every major risk must cite the evidence source: code path, config file, test, alert source, scanner output, or explicit missing evidence.
- Scanner findings must include source and collection date when available.
- Separate `Confirmed`, `Likely`, and `Needs Validation`.
- If a risk is based on absence of evidence, say exactly what was searched and what would close the gap.
- Where locally testable, run focused smoke tests, existing checks, scanner commands, or local harnesses before presenting a major risk as confirmed.
- Use temporary stubs only to isolate unavailable external services, credentials, nondeterministic providers, or slow dependencies. Do not stub the business-critical control or evidence source being evaluated.
- Clean up scratch files, local configs, scan outputs, mock services, generated harnesses, and temporary fixtures before finalizing the report unless the user asked to keep them.
- When subagents are available, ask an independent subagent to challenge high-impact executive risks for evidence quality, business impact, severity, and confidence before finalizing the report.

## Output Quality Bar

Before finalizing:

- Verify the HTML is self-contained and readable.
- Ensure no placeholder text remains.
- Ensure the top risks are understandable without security expertise.
- Ensure each executive recommendation has an owner type, urgency, and outcome.
- Ensure Dependabot/security-tooling status distinguishes checked, unavailable, disabled, and not checked.
- Ensure the appendix has enough detail for a technical reader to reproduce the assessment path.
- Ensure no unsafe exploitation instructions are included.

## Agent Workflow

1. Confirm target and scope when ambiguous.
2. Discover repository, product, or organization structure.
3. Gather architecture, appsec, dependency, CI/CD, and security-tooling evidence.
4. Analyze the actual business risk behind the technical findings.
5. Group risks into executive themes.
6. Draft the HTML report using the template.
7. Validate the report for readability, completeness, and evidence integrity.
8. Return the output path and a short summary of the posture rating and top actions.

If the user asks for only the report file, keep the chat response brief and point to the generated artifact.
