---
name: code-review
description: Performs full defensive security reviews of software repositories for vulnerabilities, authorization flaws, insecure data flows, and missing security tests. Use when reviewing a repo, application, service, codebase, PR, diff, or implementation plan.
allowed-tools: Read Grep Glob Bash
---

# Code Review

Use this skill when acting as a coding agent inside a repository. The goal is to find real, reachable security bugs and missing security controls, not to produce a generic checklist.

This skill is written for Claude Code, Codex, Cursor, and similar coding agents. Tool names vary by environment; use the local equivalents for file search, file reading, shell inspection, test execution, and Git diff inspection.

## Operating Principles

- Review from evidence. Do not assume architecture, trust boundaries, or framework behavior without checking the repo.
- Prefer exploitable paths over theoretical weakness. A finding needs a reachable path, affected asset, security boundary, and impact.
- Treat authorization, tenant isolation, identity, secret handling, and unsafe execution as first-class concerns.
- Keep the review defensive. Do not provide weaponized exploit chains, persistence steps, credential theft workflows, or instructions for attacking third-party systems.
- Do not change code unless the user explicitly asks for fixes. In review mode, report findings first.
- If evidence is missing, say what is missing and how to verify it.

## Review Setup

First establish the review frame:

1. Determine whether the user wants a full-repo review, diff review, or focused area review.
2. Identify the primary languages, frameworks, deployment model, package managers, and test commands from repo files.
3. Inspect `README`, architecture docs, route definitions, config files, Docker files, CI workflows, infra manifests, and auth-related code.
4. Check Git state before relying on file contents. If there are uncommitted changes, include them in scope unless the user says otherwise.
5. Avoid broad dependency installation or network calls unless they are already part of the repo workflow or the user approves them.

Useful discovery commands when available:

```sh
rg --files
git status --short
git diff --stat
git diff
```

## Review Order

Work through the repository in this order:

1. Map entry points: routes, handlers, jobs, CLIs, webhooks, and background workers.
2. Trace trust boundaries: user input, external services, files, environment variables, and database records.
3. Check authorization before sensitive reads, writes, state transitions, or tenant-scoped access.
4. Check injection surfaces: SQL, shell, template rendering, SSRF, path traversal, deserialization, and unsafe eval.
5. Check secret handling: logging, persistence, transport, client exposure, and default credentials.
6. Check whether tests would catch the bug class.

## Attack Surface Map

Build a concise map before reporting findings:

- Entry points: HTTP routes, RPC handlers, GraphQL resolvers, webhooks, CLIs, workers, schedulers, queues, browser extension hooks, mobile/deep links, and admin tools.
- Trust boundaries: users, organizations, tenants, internal services, third-party APIs, files, environment variables, browser input, model output, and database records.
- Sensitive assets: credentials, API keys, tokens, sessions, PII, payments, customer data, tenant data, audit logs, model prompts, tool outputs, and infrastructure permissions.
- Security controls: authentication, authorization, input validation, output encoding, CSRF defenses, rate limits, audit logging, sandboxing, encryption, secret storage, and policy checks.

Do not publish the full map unless it helps the user. Use it to guide the review.

## Deep Review Areas

Prioritize areas where repository-specific evidence shows risk:

### Authentication and Sessions

- Identity surface: login, signup, logout, password reset, email change, invite acceptance, impersonation, support access, SSO, OAuth, SAML, magic links, API keys, service accounts, JWTs, refresh tokens, session cookies, device trust, MFA, and account linking.
- Entry points and trust transitions: auth routes, callback handlers, middleware, session stores, token issuers/verifiers, account-recovery flows, remember-device state, background jobs, mobile deep links, and admin/support tooling that can bind or switch identity.
- Session and token lifecycle: token parsing, signature verification, issuer and audience checks, expiry, revocation, rotation, storage, transport, logout invalidation, refresh-token reuse detection, session fixation resistance, and whether privilege changes force re-authentication or session rotation.
- Account lifecycle binding: signup, invite acceptance, email verification, email change, password reset, account linking, MFA enrollment/recovery, and whether each step proves the user still controls the right identity before issuing a stronger credential.
- Third-party identity flows: OAuth/SSO/SAML state, nonce, redirect URI, issuer, audience, assertion replay, just-in-time provisioning, default role assignment, account linking, and whether the callback can be confused across tenants, environments, or user accounts.
- High-risk auth patterns: JWT algorithm confusion, decode-without-verify paths, unsigned token acceptance, weak or missing password-reset expiry, reset token leakage into logs or URLs, MFA bypass through race or replay, magic-link replay, service-account secrets with no rotation path, and support or impersonation flows that skip step-up checks.
- Cookie and browser controls: `HttpOnly`, `Secure`, `SameSite`, path/domain scoping, CSRF coupling, session identifiers in URLs, browser storage of bearer tokens, and cross-origin callback behavior.
- Account takeover paths: whether a low-privilege actor can capture another user's session, attach a second identity provider, bypass MFA recovery, swap email ownership, replay refresh tokens, or reuse a stale session after logout, reset, disablement, or tenant removal.
- Tests should prove auth failures directly: unauthenticated access denied, expired or revoked tokens rejected, wrong issuer or audience rejected, logout invalidates the right session, password reset tokens are single-use, cross-user session reuse fails, forged OAuth callbacks fail, and MFA bypass attempts are denied.

### Authorization and Tenant Isolation

- Object-level authorization before reads, writes, deletes, exports, billing actions, admin actions, and state transitions.
- Cross-tenant filters, organization membership checks, role checks, ownership checks, sharing links, invited users, impersonation, and background jobs.
- Watch for authorization in UI only, middleware bypasses, direct database access paths, batch endpoints, webhooks, and worker code that reuses user-controlled IDs.

### Injection and Unsafe Execution

- SQL, NoSQL, ORM raw queries, shell commands, template rendering, eval-like behavior, deserialization, expression languages, YAML/XML parsing, path handling, archive extraction, and dynamic imports.
- For LLM or agent systems, include prompt injection, tool input injection, untrusted model output driving privileged tools, and unsafe browser or shell automation.

### Data Exposure

- Logs, analytics, error reporting, telemetry, traces, cache keys, URLs, referrers, client bundles, local storage, exports, backups, and support tooling.
- Check whether secrets or tenant data can cross from privileged context to user-visible output.

### SSRF, Egress, and File Access

- URL fetchers, webhook testers, importers, preview generators, parsers, crawlers, storage integrations, PDF/image/video processors, and metadata endpoints.
- Check allowlists, DNS/IP validation, redirects, private network protections, file path normalization, symlink handling, and content-type assumptions.

### Supply Chain and Build Integrity

- Package manager lockfiles, install scripts, CI tokens, GitHub Actions permissions, Dockerfiles, generated code, vendored binaries, postinstall hooks, dependency pinning, release scripts, and deployment manifests.
- Report reachable supply-chain risk, not every outdated dependency.

### Cryptography and Secrets

- Prefer proven libraries and framework primitives over hand-rolled crypto. Custom crypto implementations are almost always a finding.
- Review each of the sub-areas below against the actual code, not against a generic checklist.

#### Key Generation and Randomness

- Weak RNG for security-sensitive values: using `Math.random()`, `random.random()`, `rand`, or time-seeded PRNGs to generate tokens, IDs, nonces, password reset codes, session keys, or IVs. These must use a CSPRNG (`crypto.randomBytes`, `secrets`, `os.urandom`, `crypto/rand`, `SecureRandom`).
- Predictable seeds: hardcoded, time-based, or low-entropy seeds for PRNGs that feed security values.
- Short keys: AES keys below 128 bits, RSA keys below 2048 bits, ECDSA curves below P-256, or HMAC keys shorter than the hash output.
- Static or reused IVs/nonces: a fixed IV with CBC or GCM is a critical finding (deterministic ciphertext for CBC, catastrophic nonce reuse for GCM). Check whether IVs are random per-encryption or derived uniquely from a counter.
- Insufficient entropy at boot or in containers: early-boot randomness can be weak in containers and VMs; check whether the runtime waits for entropy or reseeds.

#### Password Handling

- Hashing algorithm choice: plaintext, MD5, SHA-1, SHA-256/512 without a slow KDF are findings. Prefer bcrypt, scrypt, or Argon2id. Plain salted SHA is not acceptable for password storage.
- Work factor: bcrypt cost below 10, scrypt/Argon2 parameters tuned for speed over resistance. Compare against current hardware guidance (tune for ~100-250ms per hash on production hardware).
- Salt usage: missing salt, static salt shared across users, or salt too short. Salts must be unique per password and stored alongside the hash.
- Plaintext storage: passwords stored in plaintext, reversible encryption of passwords, or logging passwords at any stage (login, reset, registration, debug).
- Password reset tokens: must be single-use, high-entropy, expire quickly, and be invalidated after use or on login.

#### Encryption

- Mode of operation: ECB mode is a finding (leaks plaintext patterns). CBC without authentication is incomplete (padding oracle risk). Prefer AEAD modes: GCM, ChaCha20-Poly1305, or AES-GCM-SIV for nonce-misuse resistance.
- IV/nonce reuse: reusing an IV with the same key in GCM breaks confidentiality and integrity catastrophically. Check whether the IV is random, counter-based, or derived, and whether reuse is possible across encryptions.
- Authentication: unauthenticated encryption (CBC/CTR without a separate HMAC or AEAD tag) allows bit-flipping and padding oracle attacks. Verify the tag before decrypting, and verify on the ciphertext, not plaintext.
- Key derivation from passwords: PBKDF2 with low iteration counts, hardcoded salts, or HKDF used where a password KDF is needed. Use Argon2id/bcrypt/scrypt for passwords, HKDF for deriving keys from existing secrets.
- Envelope encryption: when encrypting at rest with a data key, check that the data key is wrapped by a master key in a KMS/HSM, that the wrapped key is stored alongside ciphertext, and that the plaintext data key is never persisted.
- Hardcoded keys: symmetric keys, API signing keys, or encryption keys embedded in source code, config files, or container images.

#### JWT and Tokens

- Algorithm confusion: accepting `alg: none` or allowing the token to dictate the verification algorithm (e.g., using an HMAC key as a public RSA key). The verifier must pin the expected algorithm server-side.
- Signature verification bypass: calling decode without verify, stripping verification in a code path, or trusting claims from an unsigned/unverified token.
- Audience and issuer checks: missing `aud` or `iss` validation allows tokens minted for one service to be used against another.
- Expiry enforcement: missing `exp` check, no `nbf` check, or long-lived tokens without rotation. Refresh tokens should have shorter lifetimes and rotation.
- Key rotation: verification keys that cannot be rotated, JWKS endpoints that are not fetched/refreshed, or hardcoded keys with no rotation path.
- Token storage and transport: JWTs in localStorage exposed to XSS, tokens in URLs logged by proxies, or long-lived access tokens without revocation.

#### Webhook Signatures

- HMAC verification: webhook receivers that do not verify signatures, or verify the wrong field (e.g., a header that is not the actual signature).
- Timing-safe comparison: using `==` or `===` to compare signatures enables timing attacks. Use `crypto.timingSafeEqual`, `hmac.Equal`, or `constant_time_compare`.
- Timestamp window: missing replay protection. Verify the timestamp is within an acceptable window (e.g., 5 minutes) and reject old requests.
- Replay protection: a valid signature can be replayed indefinitely unless a nonce, timestamp window, or seen-signature cache is used.
- Signature scheme: check whether the signature covers the raw body or a normalized string, and whether the receiver hashes the same input the sender did.

#### Secret Management

- Secrets in code: API keys, database passwords, signing keys, or tokens hardcoded in source, committed config files, or container images.
- Secrets in logs and error messages: full request bodies, authorization headers, connection strings, or stack traces that include secrets. Check structured logging, error reporters (Sentry, Datadog), and debug endpoints.
- Secret rotation: long-lived static keys with no rotation path. Check whether secrets are rotated, whether old keys are revoked, and whether rotation can be done without downtime.
- Dev/prod secret separation: production credentials reused in staging, dev, or test environments. Shared secrets mean a dev compromise leaks prod.
- `.env` and git: `.env` files committed to the repo, `.gitignore` missing `.env`, or example env files that contain real secrets instead of placeholders.
- Secret scanning: check whether the repo has secret scanning enabled (GitHub secret scanning, TruffleHog, Gitleaks). Missing scanning is a hardening gap.
- Default credentials: shipped default passwords, demo accounts with weak passwords, or bootstrap tokens that are never forced to change.

#### TLS Configuration

- Certificate validation: disabled verification (`verify=False`, `InsecureSkipVerify`, `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0`) is a critical finding enabling MITM.
- Minimum version: TLS 1.0/1.1 accepted. Prefer TLS 1.2 minimum, ideally 1.3-only.
- Cipher suites: weak ciphers enabled (RC4, 3DES, NULL, anonymous DH), or no control over cipher selection (accepting framework defaults without review).
- SNI handling: server-side SNI-based routing that leaks the hostname or fails to validate the presented certificate against the expected name.
- Certificate pinning: where pinning is used, check for pin rotation strategy and whether a failed pin check is fail-closed.

#### Crypto Agility

- Hardcoded algorithms: encryption or signing algorithms baked into code with no config-driven selection, making a future migration (e.g., from RSA to Ed25519, SHA-1 to SHA-256) a code change instead of a config change.
- Hardcoded key sizes: key lengths fixed in code rather than derived from policy, preventing upgrades without redeployment.
- Inability to rotate: keys stored in code or config with no KMS/secret-manager path, so rotation requires a code release.
- Multi-algorithm support: systems that should support algorithm negotiation (JWT `alg`, JOSE headers) but only implement one algorithm and fail to reject unexpected ones.

### Resilience and Abuse Controls

- Rate limits, quotas, file size limits, timeout handling, retry loops, idempotency, locking, queue poisoning, expensive queries, cache stampedes, and abuse-prone unauthenticated endpoints.

### Security Tests

- Identify whether tests cover the bug class. Missing tests are part of the finding when they make a regression likely.
- Prefer focused tests for the vulnerable path rather than broad snapshot tests.

## Finding Standard

Only report a finding when you can answer:

- What is the vulnerable code path?
- What trust boundary is crossed?
- What attacker capability is required?
- What security property fails?
- What data, permission, tenant, or system state is impacted?
- What minimal code or configuration change would fix it?
- What test would prevent regression?

If a concern is plausible but not proven, put it under `Needs Verification`, not `Findings`.

## Severity

Use severity based on reachable impact:

- Critical: reliable unauthorized access to highly sensitive data or privileged system control across users or tenants.
- High: unauthorized access or modification of sensitive data, auth bypass, privilege escalation, secret disclosure, or server-side code execution in a realistic path.
- Medium: scoped data exposure, partial authorization bypass, SSRF with limited reach, meaningful abuse, or security control bypass requiring constraints.
- Low: hardening issue with limited impact or requiring unlikely conditions.
- Informational: useful security observation without a demonstrated vulnerability.

Do not inflate severity because a vulnerability class sounds serious. Do not deflate severity because exploitation requires an authenticated low-privilege user.

## Output Format

Lead with a CSV findings list. Keep summaries secondary.

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `status` values such as `confirmed`, `needs_verification`, `pre_existing`, or `no_confirmed_findings`. Use `category` values such as `authorization`, `authentication`, `session`, `token-handling`, `oauth-sso`, `mfa`, `account-takeover`, `injection`, `ssrf`, `file-access`, `data-exposure`, `secrets`, `crypto`, `supply-chain`, `llm-agent`, `business-logic`, `abuse`, or `tests`.

Example row:

```csv
F-001,high,high,confirmed,authorization,Cross-tenant export lacks tenant filter,api/routes/exports.py:112,export job,tenant member,Export lookup uses user-controlled project_id without membership check,Tenant member can export another tenant's records,Route queues export before policy check and worker trusts queued project_id,Authorize project membership before queueing and re-check in worker,Add cross-tenant export denial test,Reviewed export route worker and tests
F-002,high,high,confirmed,token-handling,Refresh token remains valid after rotation,auth/refresh.py:84,refresh token rotation flow,former session holder,The refresh handler issues a new refresh token but does not revoke the old token family,A stolen refresh token can mint new sessions after the legitimate user rotates credentials,Reviewed refresh storage logic and found no token-family invalidation or reuse detection,Invalidate the prior token family on rotation and record reuse as a security event,Add a rotated refresh token reuse denial test,Reviewed auth handlers token store and tests
```

If no confirmed findings are found, still emit the header and one `no_confirmed_findings` informational row. Put needs-verification items, coverage, residual risk, commands run, and summary after the CSV unless the user asks for CSV only.

## Rules

- Cite concrete code locations when possible.
- Do not report theoretical issues without an executable path.
- Do not suggest broad rewrites when a narrow authorization, validation, or encoding fix solves the issue.

## Agent Workflow

1. Read repository structure and docs.
2. Identify frameworks and security-sensitive entry points.
3. Trace authentication and authorization paths before reviewing individual handlers.
4. Follow data from untrusted input to sensitive sinks.
5. Inspect tests for each confirmed or likely issue.
6. Run relevant local tests, static checks, or focused smoke tests when commands are clear and safe.
7. Use temporary stubs or mock services only to isolate unavailable external dependencies, credentials, or nondeterministic providers; never stub out the security control under review.
8. Clean up scratch files, throwaway fixtures, local config changes, temporary mock servers, and ad hoc scripts before reporting unless the user asked to keep them.
9. When subagents are available, ask an independent subagent to challenge confirmed high-impact findings for reachability, impact, severity, and missing controls before finalizing the CSV.
10. Report findings first, ordered by severity, with concrete file references.

When the repo is large, sample intelligently but explain coverage boundaries. Prefer following high-risk data flows end to end over scanning every file shallowly.
