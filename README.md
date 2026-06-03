# MindFort Security Skills

Security skills for AI coding agents.

MindFort builds continuous pen testing agents that find real vulnerabilities, help teams understand risk, and turn findings into fixes. This repository gives startup engineering teams and enterprise security teams a practical set of agent skills they can use locally with Claude Code, Codex, Cursor, and similar coding agents.

These skills are designed to help agents review code, threat model application changes, test APIs, understand authorization boundaries, and produce reports that teams can actually use.

Every skill is intentionally simple to invoke: install the skill, ask your coding agent to use it, provide the repo, PR, finding, or target scope, and expect a CSV findings list as the standard output. Report-oriented skills may also create HTML artifacts, but their risk register or appendix still uses the same CSV findings schema.

> **Work in progress:** this project is moving quickly. We expect to keep rapidly improving the skills, output formats, review depth, security coverage, and install ergonomics as real teams use them.

## What You Get

- Full-repo application security review workflows.
- PR-focused threat modeling for net-new vulnerabilities.
- Parallel branch audits that combine security/correctness and code-quality review.
- Leadership reports for non-technical leaders.
- API abuse test planning.
- Authorization and tenant-isolation review.
- CI/CD and supply-chain security review.
- SBOM, software composition, and recursive CVE/advisory review.
- Security regression test generation.
- Dedicated LLM and agentic-system security review.
- Maximum-depth ultrareview workflow for high-stakes complex vulnerability hunting.
- Clean HTML report templates for threat models and executive summaries.

The emphasis is the same as MindFort's platform: real vulnerabilities, useful evidence, low noise, and practical remediation.

## Install

Preview first:

```sh
./scripts/install.sh --dry-run
```

Install all skills for your user:

```sh
./scripts/install.sh
```

Install one skill:

```sh
./scripts/install.sh --skill repo-review
```

Install into the current project instead of your user directory:

```sh
./scripts/install.sh --scope project
```

Choose a platform:

```sh
./scripts/install.sh --platform claude
./scripts/install.sh --platform agents
./scripts/install.sh --platform cursor
```

Destination paths:

| Platform | User Install | Project Install |
| --- | --- | --- |
| Claude | `~/.claude/skills/<skill-name>/` | `.claude/skills/<skill-name>/` |
| Codex / Agent Skills | `~/.agents/skills/<skill-name>/` | `.agents/skills/<skill-name>/` |
| Cursor | `~/.cursor/skills-cursor/<skill-name>/` | `.cursor/skills/<skill-name>/` |

Useful options:

```sh
./scripts/install.sh --list
./scripts/install.sh --skill repo-review --force
./scripts/install.sh --dest /custom/skills/path
```

Each skill is a directory with a required `SKILL.md`. Supporting files such as templates, examples, scripts, and references can live beside it.

## Skill Catalog

| Skill | Use It When You Need To |
| --- | --- |
| `repo-review` | Review an entire repository for real, reachable application security issues. |
| `ultrareview` | Perform a maximum-depth security review with mandatory subagent planning, todo completion, subagent validation, local validation, and final CSV findings. |
| `pr-review` | Review a PR diff, threat model the changed behavior, and find net-new vulnerabilities. |
| `branch-review` | Run paired diff-first security/correctness and code-quality audits, then synthesize one prioritized merge-readiness list. |
| `security-diff` | Audit a branch or PR diff for net-new security issues, correctness bugs, breakage, feature-flag leaks, and devex regressions. |
| `code-quality` | Audit a branch or PR diff for maintainability, boundaries, complexity, testability, and architecture quality. |
| `code-review` | Review source code, diffs, or implementation plans for focused security issues. |
| `agent-security-review` | Review LLM, AI agent, MCP, tool-use, retrieval, memory, browser, shell, and human-approval boundaries. |
| `access-review` | Test authorization, access control, object ownership, role boundaries, and tenant isolation. |
| `api-testing` | Build a safe, authorized API abuse testing plan for real app and API workflows. |
| `security-tests` | Convert findings and threat scenarios into durable regression tests. |
| `retest` | Retest known findings with code review and targeted local smoke tests. |
| `supply-chain-review` | Review SBOM/software composition, recursive dependency CVEs, CI/CD, release workflows, containers, and supply-chain risk. |
| `finding-review` | Triage vulnerability reports, scanner output, pentest findings, and bug bounty submissions. |
| `threat-model` | Understand a codebase deeply and produce a polished HTML application security threat model. |
| `leadership-report` | Analyze product security posture and produce a non-technical executive report. |

## Standard Findings CSV

All skills that report findings, risks, retest results, or planned security test cases should emit a CSV list with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Rules:

- Use one row per finding, risk, retest result, or security test case.
- Use stable IDs such as `F-001`, `R-001`, `T-001`, or `RT-001`.
- Use severity values `critical`, `high`, `medium`, `low`, or `informational`.
- Use confidence values `high`, `medium`, or `low`.
- Keep `issue`, `impact`, `evidence`, `fix`, and `test` concise but specific enough for an engineer to act.
- Quote any CSV field that contains a comma, quote, or newline. Escape quotes by doubling them.
- If no confirmed issues are found, still emit the header and one `no_confirmed_findings` informational row that summarizes reviewed and unreviewed scope.
- Put non-finding notes, coverage, assumptions, and open questions after the CSV unless the user asks for CSV only.

## Validation Standard

Where relevant and safe, agents should validate their own findings before reporting them:

- Prefer local validation with existing tests, focused smoke tests, local dev servers, fixtures, or temporary stubs.
- Use temporary stubs only to isolate external services, nondeterministic providers, unavailable credentials, or slow dependencies. Do not replace the security control being tested with a stub.
- Keep temporary validation code outside the final patch unless the user asked for test implementation. Clean up scratch files, local routes, seed data, temporary configs, mock servers, and throwaway scripts before finishing.
- If local validation is blocked, record the blocker and the exact command, fixture, account, or environment needed.
- When the environment supports subagents or background agents, ask an independent subagent to challenge confirmed or high-impact findings before final output. The subagent should try to disprove reachability, impact, and proposed severity using the same evidence, then report agreement, downgrade, or rejection.
- Do not use subagents as a substitute for evidence. Use them to reduce false positives, catch missed context, and validate that the CSV row is defensible.
- Record local validation results and subagent agreement, downgrade, or rejection in the CSV `evidence` or `scope_notes` fields.

## Recommended Workflows

### Review A Repo

Use `repo-review` for engineering-facing findings, then `security-tests` to turn confirmed issues into tests.

```sh
./scripts/install.sh --skill repo-review
./scripts/install.sh --skill security-tests
```

### Run An Ultrareview

Use `ultrareview` for high-stakes reviews where subtle, multi-step vulnerabilities matter and the environment supports subagents.

```sh
./scripts/install.sh --skill ultrareview
```

### Review A Pull Request

Use `pr-review` when the question is not "is the whole repo secure?" but "does this PR introduce new risk?"

```sh
./scripts/install.sh --skill pr-review
```

### Review A Branch

Use `branch-review` when you want a harsh merge-readiness review that combines independent security/correctness and code-quality passes.

```sh
./scripts/install.sh --skill branch-review
./scripts/install.sh --skill security-diff
./scripts/install.sh --skill code-quality
```

### Retest Findings

Use `retest` when you have known findings and need to validate whether the current code fixes them.

```sh
./scripts/install.sh --skill retest
```

### Review An AI Agent

Use `agent-security-review` when the system uses LLMs, tools, MCP servers, retrieval, memory, browser automation, shell execution, or approval flows.

```sh
./scripts/install.sh --skill agent-security-review
```

### Build A Threat Model

Use `threat-model` when the team needs a durable artifact that explains architecture, trust boundaries, attack surface, threat scenarios, and mitigations.

```sh
./scripts/install.sh --skill threat-model
```

### Write A Leadership Report

Use `leadership-report` when leadership needs a clear picture of security posture, business risk, tooling coverage, and the next decisions to make.

```sh
./scripts/install.sh --skill leadership-report
```

## Repository Layout

```text
skills/
  agent-security-review/
    SKILL.md
  ultrareview/
    SKILL.md
  api-testing/
    SKILL.md
  threat-model/
    SKILL.md
    templates/
      threat-model-report.html
  access-review/
    SKILL.md
  branch-review/
    SKILL.md
  supply-chain-review/
    SKILL.md
  code-quality/
    SKILL.md
  security-diff/
    SKILL.md
  leadership-report/
    SKILL.md
    templates/
      leadership-report.html
  finding-review/
    SKILL.md
  pr-review/
    SKILL.md
  repo-review/
    SKILL.md
  retest/
    SKILL.md
  security-tests/
    SKILL.md
  code-review/
    SKILL.md
scripts/
  install.sh
```

## Safety Model

These skills are instructions and optional local resources. Treat every change as supply-chain sensitive.

- Skills should stay readable, auditable, and defensive.
- Skills should improve agent reasoning and evidence gathering, not add rigid exploit scripts.
- Scripts should be optional, documented, and narrow.
- Do not include offensive payload catalogs, persistence logic, credential theft workflows, or third-party exploitation instructions.
- Review diffs before installing updates.

Avoid curl-pipe-shell as the primary install path for cybersecurity skills. It trains users to execute remote code before reviewing it.

## Ongoing Updates

We will keep expanding and refining these skills as application security patterns change, agent capabilities improve, and real teams find new ways to use AI in their security workflows.

Expect continued updates across:

- new security review workflows,
- better report templates,
- stronger guidance for agentic and LLM-based applications,
- more practical regression-test patterns,
- clearer executive reporting,
- improved support for common engineering stacks and security tools.

The goal is simple: give teams useful security leverage they can run inside the tools they already use.

## About MindFort

MindFort helps teams deploy security agents across their attack surface, continuously find real vulnerabilities, and fix issues in the workflow where engineers already work.

Learn more at [mindfort.ai](https://www.mindfort.ai).

## Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute improvements and [CONTRIBUTORS.md](CONTRIBUTORS.md) for the current contributor list.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
