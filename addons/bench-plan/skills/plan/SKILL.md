---
description: Research the codebase for a ticket / PRD / feature, then produce a planning artifact — an implementation plan (default), a spec/design doc, a PRD, an ADR, or a paste-ready Kanban ticket. Use on "/plan", "plan this feature", "write a spec for…", "write an ADR for…", "draft a PRD", "make a ticket for…". Researches first, then writes.
argument-hint: [source: ticket/PRD path or description] [as plan|spec|prd|adr|ticket] [criteria=gherkin|ears|prose]
---

You're the **/plan** skill. Hand the request to the `plan-researcher` agent, which gathers context from the codebase and emits the requested artifact; then relay it for review. The deep gather is the value — the output *type* is just a flag.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- **Source** — a path (ticket/PRD/spec file) or an inline description. Pass it through verbatim.
- **Output type** — `plan` (default), `spec`, `prd`, `adr`, or `ticket`. Take it from an explicit `as <type>` / "write a spec/ADR/PRD/ticket" phrasing; otherwise **default to `plan`** (the right default when intent is clear and you're about to build). Quick guide if the user's wording implies a type:
  - *what & why, before design* → `prd`
  - *how + alternatives, non-trivial change* → `spec`
  - *record one decision (why X over Y)* → `adr`
  - *something to drop into Jira/Linear/GitHub* → `ticket`
  - *about to build it* → `plan`
- **Criteria notation** — optional `criteria=gherkin|ears|prose` override (else the project's `.bench/planning.yaml` default, else Gherkin).

## Step 2: Delegate
Task tool, `subagent_type: "plan-researcher"`, with `{ source: <path or text>, output_type: <plan|spec|prd|adr|ticket>, criteria: <override or "">, project_root: <cwd> }`.

## Step 3: Synthesize
Relay the artifact location (or "emitted inline" for a ticket) + a tight summary (the affected surface + step/criteria count + any open questions). Tell the user to review it. For a `plan` (or an approved `spec`), point them to the implement workflow (`/bench implement <plan-path>` or `/laravel implement <plan-path>`). Don't start implementing here.
