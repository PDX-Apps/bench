# bench-plan

Turn a ticket / PRD / feature description into a **technical plan** the `implement` workflow can execute.

## What it ships
- **`/plan`** skill → **`plan-researcher`** agent. Two phases: **gather** (read the source, follow code paths, inspect schema + related patterns, map the affected surface) then **plan** (ordered, file-level steps with acceptance criteria, written to `.bench/plans/`).
- **PLAN-001** pattern — the plan format (portable; consumed by `implement`).

The gather phase is the point: a plan grounded in the real codebase, not guesswork.

## Flow
```
/plan <ticket-or-description>     → writes .bench/plans/PLAN-x.md (review it)
/bench implement .bench/plans/PLAN-x.md   → executes it
```

## Install
```bash
bench addon add /path/to/bench/addons/bench-plan && bench rebuild
```
