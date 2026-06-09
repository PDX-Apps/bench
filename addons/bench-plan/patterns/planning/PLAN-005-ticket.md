# Ticket — format

A **paste-ready Kanban ticket** for Jira / Linear / GitHub Issues. It follows the industry pattern: the **ticket body is the requirements slice** (user story + testable acceptance criteria — the source of truth for *intent*), and the **technical plan is a separate part** the team drops into a comment or links, so it never competes with the ticket as the source of truth.

By default, emit **to the conversation, paste-ready** (don't write a file unless asked). Shared conventions in [PLAN-000-conventions](./PLAN-000-conventions.md).

Produce **two clearly separated parts**:

```markdown
─────────────── TICKET BODY (paste into the ticket) ───────────────

# {Concise title — what the user gets}

**Type:** {Feature | Bug | Chore}   ·   **Size:** {rough S/M/L, optional}

## Story
As a {role}, I want {capability} so that {benefit}.

## Context
{2–3 sentences a teammate needs — what exists today (grounded), why now. Link any
PRD/spec.}

## Acceptance criteria
{Testable, in the project's notation (default Gherkin — PLAN-000). This is the
"done" contract.}

## Out of scope
- {what this ticket does not cover}

─────────────── TECHNICAL PLAN (paste as a comment / linked doc) ───────────────

{The implementation plan per PLAN-001 — affected surface, dependency-ordered
tasks with `[P]` markers, test strategy, rollout/migration. Kept OUT of the ticket
body so the body stays the intent contract.}
```

## Conventions

- **Body = intent, comment = implementation.** Never fold the technical plan into the ticket body — that's the pattern modern AI-assisted teams converge on (ticket stays authoritative for *what*; the plan is derived).
- **Acceptance criteria are the handoff** — testable (PLAN-000), so they map straight to tests and to a coding agent picking up the ticket.
- **Paste-ready by default** — clean Markdown the user can drop into the tracker; write a file only on request.
- **One ticket per shippable unit.** If the work is an epic, emit the parent + child tickets, each with its own story + criteria.
- **Grounded** — context and surface come from the real gather; cite real paths in the technical-plan part.
