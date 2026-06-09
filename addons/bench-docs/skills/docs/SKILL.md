---
description: Generate or refresh audience-facing project documentation from the code — a README/feature doc, end-user guide, developer guide, or a custom doc type grounded in the actual files. Use on "/docs", "document this module", "write a user guide for…", "write a developer guide for this subsystem", "update the README for this feature". Scans the code first, then writes.
argument-hint: [what to document + which doc type: readme | user-guide | developer | a custom type]
---

You're the **/docs** skill. Hand the request to the `docs-writer` agent, which scans the relevant code and produces or refreshes docs grounded in it; then relay the result. This is *audience-facing documentation*. Two things it does **not** do: **API references** (use the `laravel-swagger` addon / OpenAPI), and **ADRs or build plans** (those are `bench-plan`) — if the ask is "record why we chose X" or "plan feature Y", point the user there.

The user's request: **$ARGUMENTS**

## Step 1: Identify
- **Subject** — the feature / module / area to document (a path or a name).
- **Doc type** — `readme` (a project/feature README), `user-guide` (end-user, what to click), `developer` (how to use/extend a module — can be technical), or a **custom type** the project defined (e.g. a marketing one-pager). If unclear, infer from the ask: *how to use/run it* → readme; *what an end user clicks* → user-guide; *how a dev uses/extends this subsystem* → developer. If `.bench/docs.yaml` lists custom types, a request can name one directly.
- **Target** — refresh an existing doc, or create a new one. You don't need to pick the location — the agent derives it from the project's placement strategy in `.bench/docs.yaml`. Only pass a `target` path when refreshing a specific existing doc.

## Step 2: Delegate
Task tool, `subagent_type: "docs-writer"`, with `{ subject: <path or name>, doc_type: <readme|user-guide|developer|custom-name>, target: <existing path or "new">, project_root: <cwd> }`. The agent reads `.bench/docs.yaml` for the type's audience/template and where the doc should live.

## Step 3: Synthesize
Relay the doc path + a tight summary (what was documented, grounded in which files). Note anything the code left ambiguous that the user should confirm.
