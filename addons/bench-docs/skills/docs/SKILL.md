---
description: Generate or refresh project documentation from the code — an ADR, a README section, or API docs grounded in the actual files. Use on "/docs", "document this module", "write an ADR for…", "update the README for this feature", "refresh the API docs". Scans the code first, then writes.
argument-hint: [what to document + which doc type: adr | readme | api]
---

You're the **/docs** skill. Hand the request to the `docs-writer` agent, which scans the relevant code and produces or refreshes docs grounded in it; then relay the result.

The user's request: **$ARGUMENTS**

## Step 1: Identify
- **Subject** — the feature / module / area to document (a path or a name).
- **Doc type** — ADR (a decision record), README (a project/feature README or section), or API docs. If unclear, infer from the ask: a *decision* → ADR; *how to use/run it* → README; *endpoints/contracts* → API.
- **Target** — refresh an existing doc, or create a new one (and where it should live).

## Step 2: Delegate
Task tool, `subagent_type: "docs-writer"`, with `{ subject: <path or name>, doc_type: <adr|readme|api>, target: <existing path or "new">, project_root: <cwd> }`.

## Step 3: Synthesize
Relay the doc path + a tight summary (what was documented, grounded in which files). Note anything the code left ambiguous that the user should confirm.
