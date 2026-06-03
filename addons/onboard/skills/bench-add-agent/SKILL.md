---
name: bench-add-agent
description: |
  Use this skill when the user wants to add a standalone worker agent without
  a paired slash command — typically a specialist analyzer called by other
  agents, or a reusable subroutine. Triggers on "/bench-add-agent", "add a
  worker agent", "create a {name} analyzer", or similar. For the common case
  (skill + paired worker), use /bench-add-skill instead.
---

# /bench-add-agent

Designs a standalone project-local worker agent under `./.bench/agents/`.

> **Note**: Most Bench workers are paired with a skill via `/bench-add-skill`,
> which generates both at once. Use `/bench-add-agent` only when you need an
> agent without a slash command — e.g., a specialist invoked by other agents.

## Usage

```
/bench-add-agent {name} "{description}"
/bench-add-agent {name} "{description}" --depth=deep
```

Examples:
- `/bench-add-agent migration-reviewer "post-generation review of migrations"`
- `/bench-add-agent model-relationship-mapper "summarize model relationships for other agents"`

## What this skill does

1. Parse `{name}` and `{description}`.
2. Delegate to the `agent-researcher` agent with a synthetic "skill summary"
   describing the standalone use case.
3. Relay the proposed agent file to the user.
4. On user approval, write to `.bench/agents/{name}.md` and run `bench rebuild`.

## What this skill does NOT do

- Generate a slash command. If you want one, use `/bench-add-skill`.
- Generate code-generation patterns. Use `/bench-add-pattern`.

## Delegation

```
Task(
  subagent_type: "agent-researcher",
  description: "Design standalone {name} agent",
  prompt: """
  Design a standalone project-local worker agent (no paired slash command).
  - name: {name}
  - description: {description}
  - project_root: {cwd}
  - bench_install_root: {bench_install_root}
  - depth: {depth}

  This is a standalone agent — invoked by other agents, not a /-command.
  Define its inputs (from the caller), workflow, verification, and report
  format per RESEARCH-agents.md.

  Await user approval before writing.
  """
)
```
