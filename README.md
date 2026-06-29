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
./scripts/install.sh --skill repo-review        # install one skill
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
| `repo-review` | Review an entire repository for real, reachable application security issues. |
| `ultrareview` | Maximum-depth security review with subagent planning, validation, and final CSV findings. |
| `pr-review` | Review a PR diff, threat model the changed behavior, and find net-new vulnerabilities. |
| `branch-review` | Paired security/correctness and code-quality audits, synthesized into one merge-readiness list. |
| `security-diff` | Audit a branch or PR diff for net-new security issues, correctness bugs, and breakage. |
| `code-quality` | Audit a diff for maintainability, complexity, testability, and architecture quality. |
| `code-review` | Review source code, diffs, or implementation plans for focused security issues. |
| `agent-security-review` | Review LLM, AI agent, MCP, tool-use, retrieval, memory, and approval boundaries. |
| `access-review` | Test authorization, access control, object ownership, role boundaries, and tenant isolation. |
| `api-testing` | Build a safe, authorized API abuse testing plan for real app and API workflows. |
| `security-tests` | Convert findings and threat scenarios into durable regression tests. |
| `retest` | Retest known findings with code review and targeted local smoke tests. |
| `supply-chain-review` | Review SBOM, dependency CVEs, CI/CD, release workflows, and supply-chain risk. |
| `finding-review` | Triage vulnerability reports, scanner output, pentest findings, and bug bounty submissions. |
| `threat-model` | Understand a codebase deeply and produce a polished HTML threat model. |
| `leadership-report` | Analyze product security posture and produce a non-technical executive report. |

## Workflows

| Workflow | Skills |
| --- | --- |
| Full repo review | `repo-review` → `security-tests` |
| High-stakes deep review | `ultrareview` |
| PR review | `pr-review` |
| Branch merge-readiness | `branch-review` + `security-diff` + `code-quality` |
| Retest known findings | `retest` |
| AI agent review | `agent-security-review` |
| Threat model | `threat-model` |
| Executive report | `leadership-report` |

```sh
# Example: full repo review
./scripts/install.sh --skill repo-review
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
