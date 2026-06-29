---
name: access-review
description: Performs deep defensive reviews of authorization, access control, role boundaries, and tenant isolation. Use when testing for IDOR, BOLA, BFLA, privilege escalation, cross-tenant data access, or broken access-control regressions.
allowed-tools: Read Grep Glob Bash
---

# Access Review

Use this skill when the user wants high-confidence testing of authorization and tenant isolation. This is one of the highest-value reviews for SaaS products, APIs, marketplaces, internal tools, and multi-tenant systems.

The goal is to prove whether users can only access the data and actions they are allowed to access. Do not stop at route-level authentication. Trace object ownership, tenant membership, roles, policies, and indirect worker or webhook paths.

## Core Principles

- Start from assets and actions, not from framework assumptions.
- Treat every user-controlled ID, organization ID, account ID, team ID, resource ID, slug, email, external ID, and path parameter as suspicious until authorization is proven.
- Distinguish authentication from authorization. A logged-in user is not automatically allowed to access every object.
- Check reads, writes, deletes, exports, bulk operations, background jobs, and state transitions.
- Report only reachable authorization failures or material missing evidence.
- Keep testing defensive and authorized. Do not provide exploitation chains against third-party systems.

## Setup

First identify:

- Tenant model: organization, workspace, team, account, project, customer, environment, or similar.
- Identity model: users, admins, service accounts, support users, API keys, bots, integrations, and impersonation.
- Role model: owner, admin, member, viewer, billing admin, support, internal operator, external collaborator.
- Resource model: objects, files, records, findings, tickets, tasks, payments, secrets, integrations, jobs, and exports.
- Enforcement points: middleware, route guards, policy functions, query scopes, ORM helpers, database RLS, service-layer checks, and UI-only gates.

Useful commands when available:

```sh
rg --files
rg -n "tenant|org|organization|workspace|team|account|project|owner|member|role|permission|policy|authorize|authz|admin|impersonat|support"
rg -n "where\\(|findUnique|findFirst|findById|getById|params\\.|query\\.|body\\.|resourceId|organizationId|tenantId|userId"
```

## Review Workflow

1. Map the tenant and identity model from schema, docs, and auth code.
2. Inventory sensitive resources and privileged actions.
3. Identify all entry points that accept resource identifiers or perform privileged state changes.
4. For each entry point, trace from request or event input to database query, policy check, and response.
5. Check whether the policy uses the authenticated subject, tenant membership, role, and resource ownership.
6. Check whether background jobs, webhooks, batch operations, exports, and admin paths re-check authorization or safely bind work to a trusted tenant.
7. Inspect tests for cross-user, cross-tenant, low-role, and unauthenticated denial cases.

## High-Risk Patterns

Look for:

- Fetching by object ID without tenant or owner scoping.
- Authorization checks after data is fetched, mutated, exported, or queued.
- UI-only role checks.
- Admin checks that trust request body, query string, client state, headers, or route params.
- Batch endpoints that validate one object but operate on many.
- Background jobs that trust user-controlled IDs from queues or webhooks.
- Webhooks that map external IDs to internal resources without ownership checks.
- Exports, reports, search, analytics, autocomplete, and count endpoints that leak cross-tenant data.
- Sharing links, invites, support access, impersonation, or delegated admin paths that bypass normal policy checks.
- Multi-step workflows where step one is authorized but later state transitions are not.
- Service accounts or API keys whose scope is broader than intended.
- Tests that cover happy-path access but not denial cases.

## Testing Strategy

When authorized test data exists, design safe tests around:

- User A cannot read, update, delete, export, or list User B's resources.
- Tenant A member cannot access Tenant B resources by swapping IDs.
- Viewer cannot perform member/admin actions.
- Member cannot perform owner/billing/support actions.
- Admin of one tenant cannot administer another tenant.
- Revoked users, expired invites, deleted memberships, disabled accounts, and rotated API keys lose access.
- Background jobs and webhooks reject forged or cross-tenant IDs.
- Bulk endpoints enforce authorization per object.
- Search and list endpoints do not reveal hidden records through metadata, counts, ordering, or timing-sensitive details.

Prefer regression tests that encode the security property directly. Avoid brittle tests that only assert one implementation detail.

When local validation is available:

- Run the narrowest local denial smoke test that proves the actor cannot cross the intended boundary.
- Use temporary fixtures, seed data, or stubbed external integrations only to create actors, tenants, resources, and unavailable dependencies. Do not stub the authorization policy, tenant filter, or ownership check being tested.
- Clean up temporary users, tenants, fixtures, config changes, and scratch tests before reporting unless the user asked you to keep implemented tests.
- When subagents are available, ask an independent subagent to challenge confirmed authorization findings by looking for an existing policy, query scope, middleware, RLS rule, or worker binding that would block the path.

## Finding Standard

A confirmed finding must answer:

- Which actor can access or change what they should not?
- Which resource or action is affected?
- Which trust boundary is crossed?
- Which check is missing, late, weak, or bypassed?
- Why existing controls do not prevent it?
- What business or customer impact follows?
- What minimal fix would bind access to the correct subject, tenant, and role?
- What denial test should be added?

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `category` values such as `idor`, `bola`, `bfla`, `tenant-isolation`, `role-boundary`, `admin-boundary`, `support-access`, `api-key-scope`, `webhook`, `worker`, `bulk-operation`, or `tests`.

Example row:

```csv
F-001,critical,high,confirmed,tenant-isolation,Finding detail route reads by id only,api/routes/findings.py:58,finding detail route,tenant member,The route fetches finding_id without binding it to the actor's organization,Tenant member can read another tenant's vulnerability report,Schema links findings to org_id but handler uses find_by_id before any org check,Query by finding_id and actor org_id through the policy layer,Add Tenant A cannot read Tenant B finding detail test,Reviewed tenant model finding route and tests
```

If no confirmed issues are found, still emit the header and one `no_confirmed_findings` informational row. Put needs-verification items, coverage, and residual risk after the CSV unless the user asks for CSV only.
