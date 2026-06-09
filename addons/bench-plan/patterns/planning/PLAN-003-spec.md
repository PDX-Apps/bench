# Spec / design doc (RFC) — format

The **how** of a non-trivial change: the proposed technical solution, the alternatives weighed, and the tradeoffs — written to be reviewed *before* code is committed. ("Spec", "design doc", and "RFC" are the same artifact under different names.) Use it when a change is architecturally significant, crosses service/module boundaries, or needs human sign-off on the approach. For the *what & why* upstream of this, see the PRD (PLAN-004); once a specific choice is locked, record it as an ADR (PLAN-002); to sequence the build, a plan (PLAN-001).

Shared conventions (location, criteria notation, grounding) are in [PLAN-000-conventions](./PLAN-000-conventions.md). Lives at `{artifact_dir}/NNN-feature-slug/spec.md`.

```markdown
# Spec: {Feature / change name}

- **Status:** {Draft | In review | Approved}
- **Author / date:** {who · YYYY-MM-DD}

## Summary
{1 short paragraph: what this proposes and the outcome it enables.}

## Context & requirements
{The problem, constraints, and what's true in the codebase today that forces this.
Link the PRD/ticket if one exists. State the requirements/acceptance criteria the
design must satisfy (PLAN-000 notation).}

## Proposed design
{The approach. Real components, modules, and seams — name actual classes/files.
Diagrams as needed (sequence/flow in text or mermaid). How data moves; where the
new code lives in THIS project's layout.}

### Data model & contracts
{Schema changes, new types/DTOs, API endpoints (method, path, request/response),
events — drawn from / fitting the real code.}

## Alternatives considered
{The serious options and why each lost. This is the part reviewers come back for —
a spec with no rejected alternatives has lost half its value.}

## Cross-cutting concerns
- **Security / authorization:** {authz, data exposure, input validation}
- **Performance / scale:** {hot paths, N+1s, caching, load}
- **Observability:** {logging, metrics, traces worth adding}

## Testing & rollout
{Test strategy (levels + key cases), and rollout: migrations, backfills,
feature-flags, phased release, rollback. State "none" explicitly where it applies.}

## Open questions
- {unresolved points needing a decision before/within implementation}
```

## Conventions

- **Alternatives are mandatory.** If you didn't weigh at least one other approach, it's probably a plan, not a spec.
- **Ground every component** in real paths/types — a design that doesn't fit the actual codebase isn't a design.
- **Right altitude** — argue the *approach*; don't enumerate every task (that's the plan) or re-litigate the product *why* (that's the PRD).
- **A spec often spawns downstream artifacts** — when a specific choice is settled, recommend capturing it as an ADR; when approved, recommend `/plan` to sequence the build.
