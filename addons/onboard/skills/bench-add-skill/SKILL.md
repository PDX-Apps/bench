---
name: bench-add-skill
description: |
  Use this skill when the user wants to add a custom slash command for this
  project. Triggers on "/bench-add-skill", "add a slash command for X",
  "scaffold a /saga command", "create a custom skill", or any request to
  build a project-local generation workflow. ALWAYS generates both the skill
  AND a paired worker agent — never a skill alone.
---

# /bench-add-skill

Designs a project-local slash command skill AND its paired worker agent. Both
get written under `./.bench/`.

## Usage

```
/bench-add-skill {name} "{description}"               # standard
/bench-add-skill {name} "{description}" --depth=deep  # thorough scan
```

Examples:
- `/bench-add-skill saga "scaffold a Saga + event + test + route registration"`
- `/bench-add-skill audit-trail "add audit trail to a model with migration + listener"`

## What this skill does

1. Parse `{name}` and `{description}`.
2. Delegate to the `skill-researcher` agent. The skill-researcher will in turn
   delegate to `agent-researcher` for the paired worker — both files come out
   of one flow.
3. Relay the findings report + proposed SKILL.md + proposed worker agent file
   to the user.
4. On user approval, both files are written and `bench rebuild` runs.

## What this skill does NOT do

- Generate a pattern override on its own. If the skill needs a pattern that
  doesn't yet exist, the researcher will flag it — run `/bench-add-pattern`
  first (or in parallel).
- Generate a skill without a worker. Skills always pair with agents in Bench.

## Delegation

```
Task(
  subagent_type: "skill-researcher",
  description: "Design /{name} skill + paired worker",
  prompt: """
  Design a project-local slash command skill.
  - name: {name}
  - description: {description}
  - depth: {depth}
  - project_root: {cwd}
  - bench_install_root: {bench_install_root}

  Follow RESEARCH-skills.md. Confirm the artifact exists, map the full
  generation surface, identify patterns needed. Then delegate to
  agent-researcher for the paired worker.

  Await user approval before writing.
  """
)
```
