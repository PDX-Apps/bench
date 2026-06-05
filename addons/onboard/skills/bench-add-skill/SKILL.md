---
name: bench-add-skill
description: |
  Use this skill when the user wants to add a NEW slash command OR customize a
  BUNDLED one for this project. Handles two modes — (1) NEW: scaffold a brand-new
  command + paired worker for a project-specific workflow ("/bench-add-skill saga
  scaffold a saga + event + test"), and (2) FORK: read a bundled skill's body and
  modify it ("override /api to skip generating tests", "make /controller default
  to invokable", "change /vue-component to not use Pinia"). Triggers on
  "/bench-add-skill", "scaffold a /X command", "create a custom skill", "override
  the /Y skill", "I want /Z to behave differently".
---

# /bench-add-skill

Adds a new slash command + paired worker, OR forks a bundled skill (and
optionally its agent) for this project. Writes to `./.bench/skills/{name}/` and
`./.bench/agents/{name}.md` — which shadow bundled files at the same names.

## Two modes

**NEW** — design a brand-new slash command for a workflow that doesn't yet exist.
> "/bench-add-skill saga 'scaffold a Saga + event + test + route registration'"
> "/bench-add-skill audit-trail 'add audit trail to a model with migration + listener'"

**FORK** — modify how a bundled skill behaves.
> "/bench-add-skill api 'skip generating tests'"
> "Override /controller to default to invokable"
> "Make /vue-component stop suggesting Pinia stores"

The skill auto-detects intent by checking whether a bundled skill with the
given name already exists. If it does → FORK (with confirmation). If not → NEW.

## Usage

```
/bench-add-skill {name} "{what you want}"                # auto-detect
/bench-add-skill {name} "{what you want}" --depth=deep   # thorough scan (NEW mode)
```

Examples:
- `/bench-add-skill saga "scaffold a Saga + event + test + route registration"` → NEW
- `/bench-add-skill api "skip generating tests"` → FORK (`/api` is bundled)
- `/bench-add-skill vue-component "always use Composition API"` → FORK
- `/bench-add-skill crud-resource "generate a full CRUD module from a single command"` → NEW

Tip: see what's available with `/bench-list skills`. View a skill before forking with `/bench-show skill <name>`.

## What this skill does

1. Parse `{name}` and the change/description text.
2. Delegate to the `skill-researcher` agent with intent `auto`.
3. The researcher checks whether a bundled `{name}` skill exists:
   - **Yes** → FORK mode: reads bundled SKILL.md, proposes modifications.
     Decides whether the paired agent also needs forking; delegates to
     `agent-researcher` if so.
   - **No** → NEW mode: scans the project for the artifact, maps generation
     surface, identifies patterns needed; delegates to `agent-researcher` for
     the paired worker.
4. Relay the proposed file(s) to the user.
5. On approval, files written + `bench rebuild` runs.

## What this skill does NOT do

- Generate pattern overrides (use `/bench-add-pattern`).
- Generate a NEW skill without a worker — every new skill gets a paired agent.
- (In FORK mode, the agent fork is optional — only happens if the change actually affects worker behavior.)

## Delegation

```
Task(
  subagent_type: "skill-researcher",
  description: "Add or fork /{name} skill",
  prompt: """
  Add or fork a slash command.
  - intent: auto
  - name: {name}
  - description: {what the user said — for NEW, what the skill should do; for FORK, what to change}
  - depth: {depth}
  - project_root: {cwd}
  - bench_install_root: {bench_install_root}

  Follow RESEARCH-skills.md. Detect NEW vs FORK by looking up the bundled
  skill. Show proposed file(s) before writing. Await user approval.
  """
)
```
