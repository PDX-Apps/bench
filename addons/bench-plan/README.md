# bench-plan

A **deep codebase researcher** that turns a ticket / PRD / feature description into the planning artifact you ask for — grounded in the real code, not guesswork. The gather phase is the point; the output *type* is a flag.

## Artifact types
`/plan <source> as <type>` — default **`plan`**:

| Type         | Is                                                                                                      | Use when                           | Lands in                    |
|--------------|---------------------------------------------------------------------------------------------------------|------------------------------------|-----------------------------|
| **`plan`** ⭐ | implementation plan: ordered, dependency-aware tasks (`[P]` parallel markers) + test strategy + rollout | about to build; design is clear    | `specs/NNN-feature/plan.md` |
| `spec`       | design doc / RFC: the *how* + alternatives + tradeoffs                                                  | non-trivial / architectural change | `specs/NNN-feature/spec.md` |
| `prd`        | product requirements: *what & why*, stories, acceptance criteria                                        | defining intent before design      | `specs/NNN-feature/prd.md`  |
| `adr`        | architecture decision record: one decision + consequences                                               | recording *why X over Y*           | `docs/adr/NNNN-*.md`        |
| `ticket`     | paste-ready Kanban ticket (body = story + criteria) + technical plan for the comment                    | team lives in Jira/Linear/GitHub   | emitted inline              |

This mirrors the **spec → plan → tasks** pipeline that GitHub Spec Kit and AWS Kiro converge on: in-repo Markdown, one folder per feature, testable acceptance criteria.

## What it ships
- **`/plan`** skill → **`plan-researcher`** agent. GATHER (read the source, follow code paths, inspect schema + related patterns, map the affected surface) then EMIT the chosen artifact.
- **PLAN-000** — shared conventions: where artifacts live, acceptance-criteria notation, the `[P]` task markers.
- **PLAN-001…005** — the per-artifact formats (implementation plan, ADR, spec, PRD, ticket).
- **`planning` concern** + **`config/planning.example.yaml`** — captures `artifact_dir` (default `specs/`), default `criteria` notation (default **Gherkin**; EARS / prose available), and `feature_folders` into `.bench/planning.yaml`.

## Acceptance criteria
Testable by default — **Gherkin** (`Given/When/Then`), with **EARS** (`WHEN … the system SHALL …`) and plain prose available per project (`.bench/planning.yaml`) or per run (`criteria=…`).

## Flow
```
/plan <ticket-or-description>                 → specs/NNN-feature/plan.md  (review it)
/plan <ticket> as spec                        → a design doc with alternatives
/plan "use a queue for exports" as adr        → docs/adr/NNNN-*.md
/plan <feature> as ticket                     → paste-ready ticket + technical plan
/bench implement specs/NNN-feature/plan.md    → executes the plan
```

## Install
```bash
bench addon add bench-plan && bench rebuild
```
