---
name: bench-update-claudemd
description: |
  Use this skill when the user wants to create, refresh, or update the project's
  CLAUDE.md (project memory). Triggers on phrases like "/bench-update-claudemd",
  "refresh CLAUDE.md", "regenerate the project brief", "scan the project and
  update CLAUDE.md", or any request to capture project conventions in CLAUDE.md.
---

# /bench-update-claudemd

Scans the project (manifests, layout, samples, prose, git activity) and
generates or refreshes `CLAUDE.md` at the project root.

## Usage

```
/bench-update-claudemd                          # standard depth, diff if exists
/bench-update-claudemd --depth=shallow          # quick scan (≤5 files)
/bench-update-claudemd --depth=deep             # thorough (≤100 files)
/bench-update-claudemd --force                  # overwrite existing instead of diffing
```

## What this skill does

1. Parse args: `--depth` (default `standard`), `--force` (default false).
2. Resolve `project_root` (current working directory).
3. Delegate to the `claudemd-researcher` agent with the brief.
4. Relay the agent's findings report + proposed CLAUDE.md to the user.
5. On user approval, the agent writes the file.

## What this skill does NOT do

- Generate pattern files, skills, or agents — use `/bench-add-pattern`,
  `/bench-add-skill`, `/bench-add-agent`, or the full `/bench-onboard` flow.
- Rewrite user-written prose in an existing CLAUDE.md unless `--force` is passed.

## Delegation

```
Task(
  subagent_type: "claudemd-researcher",
  description: "Research project and produce CLAUDE.md",
  prompt: """
  Generate or refine CLAUDE.md for this project.
  - depth: {depth}
  - force: {force}
  - project_root: {cwd}

  Follow RESEARCH-claudemd.md. Show findings report first; await user
  approval before writing.
  """
)
```
