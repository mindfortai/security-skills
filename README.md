# MindFort Security Skills

Security skills for AI coding agents — Claude Code, Codex, Cursor, and similar tools.

These skills help agents review code, threat model application changes, test APIs, understand authorization boundaries, and produce reports teams can actually use. Every skill follows the same pattern: install it, ask your agent to use it, provide the repo or PR, and get a CSV findings list back.

> **Work in progress:** we're rapidly improving skills, output formats, review depth, and install ergonomics as real teams use them.

## Install

**One-liner:**

```sh
curl -fsSL https://mindfort.ai/security-skills/install.sh | sh
```

**Review first:**

```sh
git clone https://github.com/mindfortai/security-skills.git
cd security-skills
./scripts/install.sh --dry-run  # preview
./scripts/install.sh            # install
```

Both methods prompt you to choose a platform (Claude Code, Codex/Agent Skills, or Cursor) and install to the appropriate directory. Pass `--platform` to skip the prompt.

### Options

```sh
./scripts/install.sh --list                     # list available skills
./scripts/install.sh --dry-run                  # preview without writing
./scripts/install.sh --skill code-review        # install one skill
./scripts/install.sh --force                    # replace existing skills
./scripts/install.sh --scope project            # install to ./.claude/skills/
./scripts/install.sh --platform cursor          # claude | agents | cursor
./scripts/install.sh --dest /custom/path        # explicit destination
```

### Destination Paths

| Platform | User Install | Project Install |
| --- | --- | --- |
| Claude | `~/.claude/skills/<skill>/` | `.claude/skills/<skill>/` |
| Codex / Agent Skills | `~/.agents/skills/<skill>/` | `.agents/skills/<skill>/` |
| Cursor | `~/.cursor/skills-cursor/<skill>/` | `.cursor/skills/<skill>/` |

## Skill Catalog

| Skill | Use It When You Need To |
| --- | --- |
| `code-review` | Review an entire repository for real, reachable application security issues — auth, authz, injection, data exposure, SSRF, crypto/secrets, supply chain, and resilience. |
| `deep-appsec-review` | Maximum-depth review with mandatory subagent planning, adversarial validation, and a strict evidence bar. Use when false positives must be rare and findings drive shipping, compliance, or disclosure decisions. |
| `pr-review` | Review a PR or branch diff, threat model the changed behavior, and report net-new security vulnerabilities, correctness bugs, and operability regressions. |
| `branch-review` | Orchestrate paired security and code-quality audits for a branch, then synthesize one prioritized merge-readiness list. |
| `code-quality` | Audit a diff for maintainability, complexity, testability, and architecture regressions. |
| `agent-security-review` | Review LLM, AI agent, MCP, tool-use, retrieval, memory, browser, shell, and approval boundaries. |
| `access-review` | Test authorization, access control, object ownership, role boundaries, and tenant isolation. |
| `api-testing` | Build a safe, authorized API abuse testing plan for real app and API workflows. |
| `security-tests` | Convert findings and threat scenarios into durable regression tests. |
| `retest` | Retest known findings with code review and targeted local smoke tests. |
| `supply-chain-review` | Review dependencies, CI/CD, build scripts, release workflows, containers, and supply-chain risk. |
| `compliance-review` | Map codebase security controls to compliance frameworks (SOC 2, ISO 27001, NIST CSF, HIPAA, PCI-DSS) and identify gaps. |
| `finding-review` | Triage vulnerability reports, scanner output, pentest findings, and bug bounty submissions. |
| `threat-model` | Understand a codebase deeply and produce a polished HTML threat model. |
| `leadership-report` | Produce an executive security posture report for non-technical leaders. |

## Workflows

| Workflow | Skills |
| --- | --- |
| Full repo review | `code-review` → `security-tests` |
| High-stakes deep review | `deep-appsec-review` |
| PR review | `pr-review` |
| Branch merge-readiness | `branch-review` (uses `pr-review` + `code-quality`) |
| Retest known findings | `retest` |
| AI agent review | `agent-security-review` |
| Compliance gap analysis | `compliance-review` |
| Threat model | `threat-model` |
| Executive report | `leadership-report` |

```sh
# Example: full repo review
./scripts/install.sh --skill code-review
./scripts/install.sh --skill security-tests
```

## Standard Findings CSV

All skills that report findings emit a CSV with this header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

- One row per finding, risk, retest result, or test case.
- Stable IDs: `F-001`, `R-001`, `T-001`, `RT-001`.
- Severity: `critical`, `high`, `medium`, `low`, `informational`.
- Confidence: `high`, `medium`, `low`.
- Quote fields containing commas, quotes, or newlines. Escape quotes by doubling.
- If no confirmed issues, emit the header plus one `no_confirmed_findings` informational row.
- Put non-finding notes after the CSV unless asked for CSV only.

## Validation Standard

Where relevant and safe, agents should validate findings before reporting:

- Prefer local validation with existing tests, smoke tests, dev servers, or fixtures.
- Use temporary stubs only to isolate external services — never replace the security control being tested.
- Clean up scratch files, mock servers, and throwaway scripts before finishing.
- If validation is blocked, record the blocker and the exact command or environment needed.
- When subagents are available, ask an independent subagent to challenge confirmed or high-impact findings before final output.
- Record validation results in the CSV `evidence` or `scope_notes` fields.

## Safety Model

These skills are instructions and optional local resources. Treat every change as supply-chain sensitive.

- Skills stay readable, auditable, and defensive.
- No offensive payload catalogs, persistence logic, credential theft, or exploitation instructions.
- Scripts are optional, documented, and narrow.
- Review diffs before installing updates.

Both `curl | sh` and `git clone` install paths are supported. For cybersecurity skills, we recommend reviewing the install script first. Use `--dry-run` to preview.

## About

MindFort helps teams deploy security agents across their attack surface, continuously find real vulnerabilities, and fix issues where engineers already work. Learn more at [mindfort.ai](https://www.mindfort.ai).

## Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute and [CONTRIBUTORS.md](CONTRIBUTORS.md) for the current contributor list.

## License

MIT — see [LICENSE](LICENSE).
