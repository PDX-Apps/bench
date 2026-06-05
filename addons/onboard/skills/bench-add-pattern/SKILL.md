---
name: bench-add-pattern
description: |
  Use this skill when the user wants to add OR customize a Bench pattern for
  this project. Handles two modes — (1) FORK a bundled pattern and modify it
  ("override the controller pattern to use cache() instead of DI", "change the
  service pattern to use Laravel magic helpers", "drop the test section from
  CTRL-001"), and (2) CAPTURE a project-specific convention as a new pattern
  ("we extend BaseController in this project", "document how our stores work").
  Triggers on "/bench-add-pattern", "override the X pattern", "change how Bench
  generates Y", "I prefer X over Y in this project's code", "add a pattern for
  our custom Z".
---

# /bench-add-pattern

Adds or customizes a Bench pattern for this project. Writes to
`./.bench/patterns/{group}/{name}.md` — which shadows the bundled pattern at
the same path during install.

## Two modes

**FORK** — start from a bundled default and modify it.
> "/bench-add-pattern controller — change it to use cache() instead of DI"
> "Override the resource controller pattern: drop the Don't section"
> "I prefer Laravel magic helpers; rewrite the service pattern accordingly"

**CAPTURE** — scan the project, identify how the team already does X, write a
pattern reflecting that.
> "/bench-add-pattern controller"  (no specific change → scan + capture)
> "Document how we extend BaseController in this codebase"

The skill (and its researcher) auto-detect intent from what the user says. If
ambiguous, the researcher will ask.

## Usage

```
/bench-add-pattern {domain-or-pattern-name}                    # auto-detect mode
/bench-add-pattern {domain-or-pattern-name} --depth=shallow    # quick
/bench-add-pattern {domain-or-pattern-name} --depth=deep       # thorough
```

Examples:
- `/bench-add-pattern controller` — auto: if user described a change → FORK; else CAPTURE
- `/bench-add-pattern CTRL-001-resource-controllers` — explicit pattern name, defaults to FORK
- `/bench-add-pattern pinia-store` — usually CAPTURE (no exact bundled match by that name)
- `/bench-add-pattern vue-component "use Composition API only, drop Options API examples"` — FORK

Tip: see what's available with `/bench-list patterns`. View a pattern before forking with `/bench-show pattern <name>`.

## What this skill does

1. Parse the domain (and any change description in the user's request).
2. Delegate to the `pattern-researcher` agent with the detected intent.
3. Relay the findings report + proposed pattern (or diff for FORK) to the user.
4. On user approval, the agent writes to `.bench/patterns/{group}/{name}.md` and runs `bench rebuild`.

## What this skill does NOT do

- Generate a paired skill or agent (use `/bench-add-skill` for that).
- Modify Bench core patterns directly. Overrides land in `./.bench/`, which
  shadows the bundled at the same path.
- Touch files outside `.bench/`.

## Delegation

```
Task(
  subagent_type: "pattern-researcher",
  description: "Add/fork {domain} pattern",
  prompt: """
  Add or customize a Bench pattern.
  - intent: auto
  - domain: {domain}
  - change_request: {free-form text from user request, or empty if just a domain name}
  - depth: {depth}
  - project_root: {cwd}
  - bench_install_root: {bench_install_root}

  Follow RESEARCH-patterns.md. Detect FORK vs CAPTURE intent. Show the diff
  (FORK) or findings (CAPTURE) before writing. Await user approval.
  """
)
```
