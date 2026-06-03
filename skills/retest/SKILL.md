---
name: retest
description: Retests known findings by using findings from the current conversation or asking for a list, then reviewing the relevant code and running targeted local smoke tests when possible. Use when validating whether reported issues are fixed or still reproducible.
allowed-tools: Read Grep Glob Bash
---

# Retest

Use this skill when the user wants to validate known findings against the current code.

Start with findings already present in the conversation. If the conversation does not include enough detail, ask the user for the finding list before testing. Do not invent findings.

## Inputs

For each finding, identify:

- Title or claim.
- Affected feature, endpoint, file, or workflow.
- Expected vulnerable behavior.
- Expected fixed behavior.
- Any provided proof, reproduction steps, test account roles, or payload shape.

If key details are missing, ask for the smallest missing set needed to retest.

## Workflow

1. Build a short retest queue from the current conversation or the user's provided list.
2. Locate the changed code, relevant tests, routes, handlers, policies, and fixtures.
3. Review whether the current code appears to remove the vulnerable behavior.
4. Run the narrowest local smoke test that can safely validate the security property.
5. Prefer existing tests, local dev servers, test fixtures, and safe read-only probes.
6. Do not run destructive, high-volume, production, or third-party tests without explicit approval.
7. Record what was verified, what failed, and what could not be tested locally.

## Smoke Test Rules

- Keep tests targeted to the finding.
- Use local or test environments only unless the user explicitly authorizes another target.
- Verify both the negative case and, when useful, a positive control.
- Do not treat a passing unit test as proof if it skips the real security control.
- Do not mark a finding fixed from code review alone when a practical local test exists.
- Use temporary stubs only for unavailable third-party services, credentials, nondeterministic providers, or slow dependencies. Do not stub the security control or vulnerable path being retested.
- Clean up scratch tests, temporary fixtures, local data, mock servers, config changes, and throwaway scripts before reporting unless the user asked to keep them as regression tests.
- When subagents are available, ask an independent subagent to challenge any `fixed`, `still_vulnerable`, or high-impact `partially_fixed` result before finalizing it.
- If local execution is blocked, explain the blocker and provide the exact command or setup needed.

## Output Format

Output retest results as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `fixed`, `still_vulnerable`, `partially_fixed`, `not_reproducible`, `blocked`, or `needs_verification`. Keep the original severity when known; otherwise use the retester's best evidence-based severity.

For retest rows, use:

- `issue`: what vulnerable behavior was retested.
- `impact`: impact if still vulnerable.
- `evidence`: code review facts plus smoke-test result or blocker.
- `fix`: remaining remediation if not fixed, or the fix observed if fixed.
- `test`: command, local action, or missing setup needed to reproduce.
- `scope_notes`: residual risk, confidence limits, and next step.

Put the overall fixed/still-vulnerable/blocked counts and commands run after the CSV unless the user asks for CSV only.

## Quality Bar

- Be evidence-led and concise.
- Separate code-review confidence from runtime-test confidence.
- Do not overstate what was proven.
- Preserve enough command output or file references for another engineer to reproduce the retest.
