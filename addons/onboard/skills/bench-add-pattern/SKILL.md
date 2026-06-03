---
name: bench-add-pattern
description: |
  Use this skill when the user wants to capture a project-specific code
  convention as a Bench pattern override. Triggers on "/bench-add-pattern",
  "add a pattern for X", "override the controller pattern", "capture our
  custom store convention", or any request to document an artifact-specific
  convention for AI code generation.
---

# /bench-add-pattern

Researches a specific artifact domain in the project (controllers, stores,
components, form requests, etc.) and produces a project-local pattern override
under `./.bench/patterns/`.

## Usage

```
/bench-add-pattern {domain}                     # standard depth
/bench-add-pattern {domain} --depth=shallow     # quick scan
/bench-add-pattern {domain} --depth=deep        # thorough
```

Examples:
- `/bench-add-pattern controller`
- `/bench-add-pattern pinia-store`
- `/bench-add-pattern vue-component`
- `/bench-add-pattern form-request`

## What this skill does

1. Parse the domain argument.
2. Delegate to the `pattern-researcher` agent.
3. Relay the findings report + proposed pattern file to the user.
4. On user approval, the agent writes to `.bench/patterns/{group}/{name}.md`
   and runs `bench rebuild`.

## What this skill does NOT do

- Generate a paired skill or agent — use `/bench-add-skill` for that.
- Modify Bench core patterns. Overrides land in `./.bench/`.
- Touch files outside `.bench/`.

## Delegation

```
Task(
  subagent_type: "pattern-researcher",
  description: "Research {domain} and produce pattern override",
  prompt: """
  Research the {domain} convention in this project and produce a pattern
  override.
  - domain: {domain}
  - depth: {depth}
  - project_root: {cwd}
  - bench_install_root: {bench_install_root}

  Follow RESEARCH-patterns.md. Show findings + diff vs Bench base pattern.
  Await user approval before writing.
  """
)
```
