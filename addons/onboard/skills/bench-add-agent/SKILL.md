---
name: bench-add-agent
description: |
  Use this skill when the user wants to add a NEW standalone worker agent OR
  customize a BUNDLED agent. Handles two modes — (1) NEW: design a standalone
  agent (specialist analyzer called by other agents, or reusable subroutine);
  (2) FORK: read a bundled agent's body and modify it ("override the controller
  agent to run pint with a custom config", "make the migration agent skip
  phpstan", "change the api agent's report format"). Triggers on
  "/bench-add-agent", "add a worker agent", "override the {name} agent",
  "customize how the {name} agent behaves". For the common case (skill + paired
  worker), use /bench-add-skill instead.
---

# /bench-add-agent

Adds a new standalone worker agent OR forks a bundled agent. Writes to
`./.bench/agents/{name}.md` — which shadows the bundled agent at the same
name during install.

## Two modes

**NEW** — design a brand-new standalone agent (no paired slash command).
> "/bench-add-agent migration-reviewer 'post-generation review of migrations'"
> "/bench-add-agent model-relationship-mapper 'summarize relationships for other agents'"

**FORK** — modify how a bundled worker behaves.
> "/bench-add-agent controller 'run pint with --preset=psr12'"
> "Override the migration agent: skip the phpstan step"
> "Make the api agent's report shorter"

Auto-detects by checking if a bundled agent exists with that name.

> **For the common case (slash command + paired worker)**, use `/bench-add-skill`
> instead — it generates both in one flow. `/bench-add-agent` is for standalone
> agents (no paired skill) or forking an existing bundled worker.

## Usage

```
/bench-add-agent {name} "{description-or-change}"
/bench-add-agent {name} "{description-or-change}" --depth=deep
```

Examples:
- `/bench-add-agent migration-reviewer "post-generation review of migrations"` → NEW
- `/bench-add-agent controller "run pint with --preset=psr12"` → FORK (`controller` is bundled)
- `/bench-add-agent model-relationship-mapper "summarize relationships"` → NEW

Tip: see what's available with `/bench-list agents`. View an agent before forking with `/bench-show agent <name>`.

## What this skill does

1. Parse `{name}` and the description/change text.
2. Delegate to the `agent-researcher` agent with intent `auto`.
3. The researcher checks whether a bundled `{name}` agent exists:
   - **Yes** → FORK mode: reads bundled agent, proposes modifications.
   - **No** → NEW mode: designs a standalone agent (no paired skill).
4. Relay the proposed file to the user.
5. On approval, write to `.bench/agents/{name}.md` + run `bench rebuild`.

## What this skill does NOT do

- Generate a slash command. If you want one, use `/bench-add-skill`.
- Generate code-generation patterns. Use `/bench-add-pattern`.

## Delegation

```
Task(
  subagent_type: "agent-researcher",
  description: "Add or fork {name} agent",
  prompt: """
  Add or fork a worker agent.
  - intent: auto
  - name: {name}
  - change_request: {what the user said}
  - project_root: {cwd}
  - bench_install_root: {bench_install_root}
  - depth: {depth}

  Follow RESEARCH-agents.md. Detect NEW vs FORK by looking up the bundled
  agent at {bench_install_root}/agents/{name}.md. Show the proposed file
  (NEW) or diff (FORK) before writing. Await user approval.
  """
)
```
