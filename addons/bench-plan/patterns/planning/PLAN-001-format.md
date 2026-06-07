# Technical plan — format

The plan the `/plan` flow writes and the `implement` workflow consumes. Portable + structured: describe *what each step produces*, not a brittle command script.

```markdown
# Plan: {Feature name}

## Summary
{1–3 sentences: what we're building and why, from the PRD/ticket.}

## Acceptance criteria
- [ ] {observable outcome 1}
- [ ] {observable outcome 2}

## Affected surface
{Files/areas the research found — real paths.}
- `app/...` — {role}
- `src/...` — {role}

## Steps
1. **{Step name}** — {what it produces}
   - Artifact(s): {files to create/modify}
   - Handled by: {Bench skill/agent, e.g. /migration, /controller, /vue-component}
   - Done when: {step-level acceptance}
2. ...

## Edge cases & risks
- {edge case / risk + how the plan addresses it}

## Open questions
- {anything the source didn't answer — resolve before implementing}
```

## Conventions

- **Order steps by dependency**: data/schema → backend (model/action/controller/route) → API (resource) → frontend (types/validators → query → components → page → route) → tests.
- **One artifact-type per step** where possible, named with the Bench skill that handles it — so `implement` (or the user) can map each step to an agent.
- **Acceptance criteria are observable** (an endpoint returns X, a page shows Y), not "code is written".
- **Stay portable** — no project-specific command DSL; the plan reads cleanly to a human and to the implement workflow.
