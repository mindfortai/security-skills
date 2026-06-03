# Contributing

Thanks for improving MindFort Security Skills. This repository is a work in progress and we expect the skills to evolve quickly as engineers use them in real reviews.

## What Makes A Good Contribution

- Keeps the skill simple for an engineer to invoke.
- Improves the agent's reasoning, context gathering, validation, or evidence quality.
- Finds real security risk with a high signal-to-noise ratio.
- Preserves defensive safety boundaries.
- Uses the standard CSV findings format for outputs.
- Avoids rigid exploit scripts, payload catalogs, target-specific hacks, and brittle prompt patches.

## Skill Requirements

Every skill must live in `skills/<skill-name>/SKILL.md` and start with YAML frontmatter:

```md
---
name: skill-name
description: Clear trigger description for when an agent should use this skill.
allowed-tools: Read Grep Glob Bash
---
```

Use lowercase kebab-case names. The frontmatter `name` must match the folder name.

Descriptions matter. Keep them concise and front-load the trigger terms an agent should match, such as `repo review`, `SBOM`, `API testing`, `authorization`, `agent security`, or `retest`.

## Output Standard

Skills that report findings, risks, retest results, or planned security test cases must emit this CSV header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Rows should be concise, actionable, and evidence-backed. If there are no confirmed issues, emit the header plus one `no_confirmed_findings` informational row.

## Validation Standard

Where relevant and safe, skills should tell agents to validate their work:

- Run local tests, focused smoke tests, static checks, or local harnesses when available.
- Use temporary stubs only for unavailable external services, credentials, nondeterministic providers, or slow dependencies.
- Never stub the security control being tested.
- Clean up temporary fixtures, mock servers, generated files, local config changes, and scratch scripts before final output unless the user asked to keep tests.
- Use subagents to challenge high-impact findings when the environment supports them.

## Safety Boundaries

Do not add:

- Offensive payload catalogs.
- Persistence, credential theft, or evasion workflows.
- Instructions for attacking third-party systems.
- Installers that fetch and execute remote code before review.
- Broad scripts that write outside the repo or require production credentials.

Prefer source review, local validation, safe test plans, and owner-authorized checks.

## Adding Or Updating A Skill

1. Add or edit `skills/<skill-name>/SKILL.md`.
2. Keep the scope focused. If a skill tries to do three unrelated jobs, split it.
3. Prefer instructions over scripts unless deterministic local tooling is truly useful.
4. If a skill includes scripts or templates, keep them narrow and documented.
5. Update `README.md` when adding a new skill or changing install/user-facing behavior.
6. Run validation before opening a PR.

## Validation Commands

Run:

```sh
./scripts/install.sh --list
git diff --check
rg --files-without-match 'id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes' skills/*/SKILL.md
```

The final command should produce no output. Exit code `1` from `rg --files-without-match` is acceptable when every skill contains the standard header.

## Review Bar

Contributions should make the agent more useful to engineers, not just longer. The strongest changes usually:

- clarify what evidence is required,
- add missing security domains,
- improve local validation,
- reduce false positives,
- improve CSV consistency,
- make output easier to import into issue trackers or spreadsheets,
- or make skills easier to install and invoke.

## Contributor List

Add new names to `CONTRIBUTORS.md` only when the contributor wants to be listed.
