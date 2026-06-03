---
name: bench-onboard
description: |
  Use this skill when the user wants to onboard Bench to a project from scratch
  — a comprehensive first-time setup that scans the codebase, generates
  CLAUDE.md, and proposes any project-local pattern overrides, skills, and
  agents needed. Triggers on "/bench-onboard", "set up Bench for this project",
  "do a full onboarding scan", "make Bench fit my project". The all-in-one
  starting point.
---

# /bench-onboard

The all-in-one onboarding workflow. Scans the project, generates `CLAUDE.md`,
identifies candidates for pattern overrides / custom skills / custom agents,
and walks the user through approving each.

## Usage

```
/bench-onboard                          # standard depth, interactive
/bench-onboard --depth=shallow          # quick — CLAUDE.md only, light scan
/bench-onboard --depth=deep             # thorough — scans extensively, proposes more
/bench-onboard --no-interview           # skip user-interview step (Layer 6)
```

## What this skill does

The flow has 4 phases. Each phase gets the user's approval before moving on.

### Phase 1 — Scan + CLAUDE.md

1. Delegate to `claudemd-researcher` with the chosen depth.
2. Show the findings report.
3. Show the proposed CLAUDE.md (or diff for existing).
4. Get user approval; write CLAUDE.md.
5. Collect the researcher's "recommended follow-ups" list.

### Phase 2 — Pattern overrides (proposed from follow-ups)

For each candidate domain flagged in Phase 1:

1. Ask the user: "Want to capture {domain} as a pattern override? (y/n/skip-all)"
2. If yes: delegate to `pattern-researcher` for that domain.
3. Show findings + proposed pattern file.
4. On approval: write `.bench/patterns/{group}/{name}.md`.

Run rebuild once after all approved patterns are written.

### Phase 3 — Custom skills (if any are warranted)

If Phase 1 surfaced project-specific workflows that don't map to existing Bench
skills:

1. Ask the user: "Want to scaffold a /{name} skill for {workflow}? (y/n)"
2. If yes: delegate to `skill-researcher` (which in turn delegates to
   `agent-researcher` for the paired worker).
3. Show both proposed files.
4. On approval: write both, run rebuild.

### Phase 4 — Summary + next steps

Show the user:
- Files written (CLAUDE.md, pattern overrides, skill+agent pairs)
- Suggested next commands to try
- How to add more later (`/bench-add-pattern`, `/bench-add-skill`, etc.)

## What this skill does NOT do

- Push to git. The user reviews changes themselves.
- Install Bench (the CLI did that). This is post-install onboarding.
- Lock the user into anything. Every change is opt-in; "skip" is always valid.

## Depth modes

| Mode | CLAUDE.md scan | Pattern candidates surfaced | Skill candidates surfaced |
|------|----------------|----------------------------|--------------------------|
| shallow | ≤5 files | 0 (skipped) | 0 (skipped) |
| standard (default) | ≤25 files | up to 3 | up to 2 |
| deep | ≤100 files | up to 10 | up to 5 |

The user can always run targeted skills (`/bench-add-pattern`, `/bench-add-skill`)
later — onboarding doesn't need to capture everything on day one.

## Delegation

This skill orchestrates. Each phase delegates to a researcher; the user
reviews between phases.

```
# Phase 1
Task(subagent_type: "claudemd-researcher", ...)

# Phase 2 (per accepted candidate)
Task(subagent_type: "pattern-researcher", ...)

# Phase 3 (per accepted candidate)
Task(subagent_type: "skill-researcher", ...)
```

## Final report

```
Bench onboarded.

Created:
- CLAUDE.md
- .bench/patterns/laravel/controller.md
- .bench/skills/saga/SKILL.md
- .bench/agents/saga-worker.md

Try:
- /saga create OrderShipped
- /api create endpoint to list users

Add more later with:
- /bench-add-pattern {domain}
- /bench-add-skill {name} "{description}"
- /bench-update-claudemd
```
