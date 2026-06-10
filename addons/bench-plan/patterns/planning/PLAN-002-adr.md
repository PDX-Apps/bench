# Architecture Decision Record (ADR) — format

An ADR captures **one significant decision**: the context that forced it, the choice made, and the consequences that follow. It's a dated, immutable record — when a decision changes, you write a *new* ADR that supersedes the old one rather than editing history.

## When to write one

- A choice that is **hard or costly to reverse** (datastore, framework, auth model, public API shape, sync vs async boundary).
- A choice that **future readers will question** ("why is this an event, not a direct call?").
- A choice with **non-obvious trade-offs** you want on record.

Don't write one for trivial or easily-reversible decisions — that's noise.

## Where it lives

The **decision log**, separate from feature artifacts — conventionally `docs/adr/NNNN-short-title.md`, numbered in order (`0001-…`, `0002-…`), one decision per file. Detect an existing location first (`docs/adr/`, `docs/decisions/`, `doc/adr/`) and use it; else default `docs/adr/` and confirm.

## Format

```markdown
# ADR-{NNNN}: {Short decision title}

- **Status:** {Proposed | Accepted | Superseded by ADR-XXXX}
- **Date:** {YYYY-MM-DD}

## Context

{The forces at play: the problem, constraints, requirements, and what's true
in the codebase today that makes this decision necessary. Neutral — no choice yet.}

## Decision

{The choice made, stated plainly in active voice: "We will …". Include the key
alternatives considered and why they lost — that's the part readers come back for.}

## Consequences

{What becomes easier and what becomes harder as a result. Follow-on work,
new constraints, risks accepted. Both positive and negative — honest trade-offs.}
```

## Conventions

- **One decision per ADR.** If you're explaining two decisions, write two.
- **Immutable.** Don't rewrite an accepted ADR; supersede it (set the old one's status to `Superseded by ADR-XXXX`).
- **Ground it in the code** — the context and decision should reflect what the codebase actually does, with real paths/names where relevant.
- **State the alternatives.** An ADR that doesn't say what was rejected, and why, has lost half its value.
