# Security Policy

This repository contains agent skills for defensive cybersecurity work.

## Scope

In scope:

- Unsafe skill instructions that could cause data exfiltration.
- Instructions that enable unauthorized exploitation of third-party systems.
- Bundled scripts or resources that perform unexpected network, filesystem, or credential access.
- Ambiguous instructions that make Claude likely to exceed an authorized defensive workflow.

Out of scope:

- Requests for offensive payload libraries.
- Requests to bypass authorization or exploit systems without permission.
- Generic prompt-injection behavior in upstream models or products.

## Reporting

Report issues privately through GitHub Security Advisories:

https://github.com/mindfortai/security-skills/security/advisories/new

Include:

- The affected skill name.
- The risky instruction or file path.
- A concrete scenario where the behavior could cause harm.
- A proposed remediation, if known.

## Maintainer Expectations

- Review all skill changes before release.
- Keep skills defensive, auditable, and scoped.
- Prefer improving agent reasoning and evidence requirements over adding rigid checklists.
- Avoid installers that execute remote code before users can inspect it.

