# Implementation plan — format

The **default** bench-plan artifact, and the one the `implement` workflow consumes: a design summary grounded in the real codebase, then an ordered, dependency-aware task list. Use it when intent is clear and you're about to build. (For the *how + alternatives* of a non-trivial change, write a spec; for *what & why*, a PRD.) This file is the plan's structure.

```markdown
# Plan: {Feature name}

## Summary
{1–3 sentences: what we're building and why, from the source.}

## Acceptance criteria
{Testable criteria in the project's notation (default Gherkin).}

## Affected surface
{Files/areas the gather found — real paths.}
- `app/...` — {role}
- `src/...` — {role}

## Approach
{2–4 sentences on the technical approach: the key seam(s) touched, the pattern
followed, anything non-obvious. Not a full design doc — just enough to orient the
implementer. If the change is architecturally non-trivial, recommend a spec first.}

## Tasks
{Dependency-ordered; `[P]` marks parallelizable. Each names its artifact(s) + the
Bench skill/agent that handles it + step-level "done when".}

1. [ ] {Task} → {/skill} ({layer})
   - Artifact(s): {files}
   - Done when: {observable step acceptance}
2. [ ] [P] {Task} → {/skill}  (depends: 1)
   - ...

## Test strategy
{How the feature is verified: which levels (unit / feature / e2e), the key cases
incl. edge/negative, and the project's test command. Tie each acceptance criterion
to at least one test. Omit only if there is genuinely nothing to test.}

## Rollout / migration
{Data migrations, backfills, feature-flagging, phased rollout, and rollback. State
"none — no data or rollout impact" explicitly when that's the case, so it's clear
it was considered, not forgotten.}

## Edge cases & risks
- {edge case / risk + how the plan addresses it}

## Open questions
- {anything the source didn't answer — resolve before implementing}
```

## Conventions

- **Tasks are the contract with `implement`** — one artifact-type per task where possible, named with the Bench skill that handles it, dependency-ordered with `[P]` markers.
- **Acceptance criteria are observable and testable** — and every one is covered by the Test strategy.
- **Test strategy and Rollout/migration are included by default** — they're what makes a plan enterprise-grade. Write "none" explicitly rather than dropping the section, so reviewers see it was considered.
- **Right altitude** — a plan sequences building one feature; it's not a design doc (no long alternatives analysis — that's a spec) and not a decision record (no context/consequences essay — that's an ADR).
- **Stay portable** — no project-specific command DSL; reads cleanly to a human and to the implement workflow.
