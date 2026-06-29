---
name: agent-security-review
description: Reviews LLM and AI agent systems for prompt injection, unsafe tool use, context leakage, approval bypasses, and missing security tests. Use when auditing AI agents, MCP servers, tool routers, retrieval systems, or autonomous workflows.
allowed-tools: Read Grep Glob Bash
---

# Agent Security Review

Use this skill when reviewing AI agents, LLM applications, MCP servers, tool routers, retrieval systems, memory layers, browser automation, shell/code execution, autonomous workflows, or human-approval gates.

The goal is to find places where untrusted content, model output, retrieved context, or tool results can cause the system to reveal data, cross tenant boundaries, perform privileged actions, or make unsafe decisions. Do not solve nondeterministic agent failures with brittle keyword filters or target-specific prompt patches. Prefer stronger context, clearer authority boundaries, smaller tool permissions, provenance, policy checks, and tests that encode the security invariant.

## Review Frame

First identify:

- Agent purpose: what the agent is allowed to decide and what it may only recommend.
- Actors: end users, tenant admins, support users, service accounts, external content authors, tool providers, and internal operators.
- Trust boundaries: user prompt to model, retrieved content to prompt, model output to tool call, tool output to memory, tenant to tenant, browser to internal network, shell to host, and human approval to execution.
- Tools: shell, browser, filesystem, database, HTTP, email, Slack, GitHub, ticketing, billing, deployment, credential, MCP, and internal admin tools.
- Context sources: documents, webpages, emails, tickets, chat, vector stores, memories, traces, logs, prior runs, uploaded files, and tool outputs.
- Durable state: memories, task state, embeddings, cached pages, generated code, scheduled actions, approval records, and audit logs.
- Guardrails: tool allowlists, policy checks, schema validation, tenant filters, provenance, sensitive-action approvals, sandboxing, egress controls, rate limits, and regression tests.

Useful searches when available:

```sh
rg --files
rg -n "agent|llm|model|prompt|system prompt|tool|function_call|mcp|memory|retrieval|vector|embedding|browser|shell|approval|human"
rg -n "tenant|org|workspace|user_id|actor|permission|policy|secret|credential|token|api_key|admin|impersonat"
rg -n "eval|exec|subprocess|shell|playwright|browser|requests|fetch|http|webhook|database|sql|filesystem|write"
```

## High-Risk Domains

### Prompt And Context Injection

- Untrusted webpages, emails, tickets, docs, logs, or tool results placed beside privileged instructions without provenance.
- Agent instructions that let retrieved content redefine goals, tools, identity, approval state, or data boundaries.
- Summaries or memories that preserve attacker instructions as trusted future context.

### Tool Authority

- Model output directly drives shell, browser, database, network, file, deployment, billing, or admin tools.
- Tools infer authorization from prompts, UI state, thread ids, resource names, or user-controlled identifiers.
- Tool schemas accept broad free-form instructions where a narrow structured contract should carry authority.
- Sensitive tools lack explicit actor, tenant, target resource, and approval context.

### Retrieval, Memory, And Tenant Isolation

- Cross-tenant documents, embeddings, memories, traces, or tool outputs can enter another tenant's prompt.
- Retrieval filters are optional, applied after retrieval, or derived from model output.
- Memories mix observations, instructions, secrets, credentials, and conclusions without provenance or freshness.
- Agent final answers cite or expose hidden chain-of-thought, prompts, tool outputs, secrets, or customer data.

### Human Approval And Autonomy

- Approval prompts omit the actual actor, resource, operation, diff, destination, or irreversible effect.
- Approval records can be replayed, confused across tasks, or reused after scope changes.
- Background or scheduled agents continue with stale authority after revocation, logout, org switch, or permission changes.

### Browser, Shell, Code, And Network Execution

- Browser agents can reach internal admin surfaces, cloud metadata, localhost, private IPs, or customer-only URLs without policy.
- Shell/code tools run untrusted model output, generated scripts, dependency installs, or downloaded content without sandbox boundaries.
- Network fetch tools can perform SSRF, credentialed requests, or cross-tenant scraping.

### Observability And Incident Response

- Prompts, tool inputs, tool outputs, tokens, customer data, or secrets are logged into broadly visible traces.
- Audit logs cannot answer who approved what action, on which resource, with which tool output, and under which policy.
- Failure handling hides denied actions, policy errors, or partial execution from operators.

## Finding Standard

A confirmed finding must answer:

- Which untrusted input, model output, retrieved content, memory, or tool result crosses a trust boundary?
- Which tool, resource, tenant, credential, user, or durable state is affected?
- Which policy, permission, provenance, schema, sandbox, or approval check is missing or bypassable?
- Why deterministic filters or prompt-only guidance would not be a durable fix?
- What minimal architectural change restores the security invariant?
- What regression test proves the agent cannot repeat the unsafe behavior?

## Output Format

Output findings as CSV with this exact header:

```csv
id,severity,confidence,status,category,title,location,asset_or_flow,actor,issue,impact,evidence,fix,test,scope_notes
```

Use `category` values such as `prompt-injection`, `tool-authority`, `tenant-isolation`, `memory`, `retrieval`, `approval`, `browser-shell`, `data-exposure`, `observability`, or `tests`.

Example row:

```csv
F-001,high,high,confirmed,tool-authority,Model-selected org id reaches admin tool,agents/tools/admin.py:88,admin user update tool,tenant member,The tool accepts organization_id from model output instead of deriving it from the authenticated actor,Agent can modify another tenant if hostile context convinces it to choose a different org id,Tool schema exposes organization_id and handler does not re-check membership,Derive org from actor context and enforce policy inside the tool,Add a cross-tenant denial test for the tool handler,Reviewed tool router and admin user tool
```

If no confirmed findings are found, still emit the header and one `no_confirmed_findings` informational row. Put coverage, residual risk, and open questions after the CSV unless the user asks for CSV only.

## Rules

- Do not recommend brittle prompt patches as the primary fix for authorization, data isolation, or tool authority failures.
- Do not expose offensive prompt payload catalogs, credential theft workflows, persistence steps, or third-party attack instructions.
- Prefer source-of-truth policy checks in tools and resource services over agent-side reminders.
- Treat missing tests as important when the agent can perform sensitive actions or cross tenant boundaries.
- Where safe, validate findings with local harnesses, stubbed external tools, dry-run tool calls, fake tenants, fake documents, or smoke tests that exercise the real policy and tool boundary.
- Use stubs only for nondeterministic model/provider behavior, unavailable services, or unsafe external effects. Do not stub the tool authorization, tenant filter, approval gate, or memory isolation being tested.
- Clean up temporary memories, scratch documents, fake tools, mock MCP servers, local traces, generated files, and ad hoc harnesses before final output unless the user asked for durable tests.
- When subagents are available, ask an independent subagent to challenge confirmed findings by tracing whether untrusted context can really reach a privileged tool, durable memory, tenant boundary, or sensitive output.
