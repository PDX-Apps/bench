---
description: |
  View the full content of a Bench pattern, skill, or agent — usually before
  deciding to override it. Use on "/bench-show", "show me the controller pattern",
  "what's in /laravel", "view the vue-store skill", "open the migration agent".
  Pairs with /bench-list for discovery.
argument-hint: <pattern|skill|agent> <name>
---

You're the **/bench-show** skill. Display the full content of one Bench pattern, skill, or agent. Read-only.

The user's request: **$ARGUMENTS**

## Usage

```
/bench-show pattern <name>   # e.g. controller, CONTROLLER-001, model
/bench-show skill <name>     # e.g. laravel, vue-component
/bench-show agent <name>     # e.g. controller, vue-ui
```

`<name>` is matched case-insensitively (substring) against the install's files.

## Steps

1. **Parse** `<type>` and `<name>`.
2. **Resolve the install root** — `{project_root}/.claude/plugins/bench/`. Verify it exists.
3. **Find candidate(s):**
   - patterns: `find {install}/patterns-built -name '*.md' -ipath "*${name}*" -not -name '_meta.yaml'`
   - skills: `find {install}/skills -name SKILL.md -ipath "*${name}*"`
   - agents: `find {install}/agents -name '*.md' -ipath "*${name}*"`
4. **Handle the result:**
   - Zero → "not found" + suggest `/bench-list <type>`.
   - One → Read it and display the full content, with the resolved path at the top.
   - Multiple → list the candidate paths and ask which.
5. **After displaying**, append one or two short pointers:
   - `Source: {bundled core | bundled addon: <name> | project-local at ./.bench/}`
   - `To change it for this project: /bench-override (describe what you want different) — it forks into ./.bench/, shadowing the bundled version.`

## What this skill does NOT do

- Modify the file (use `/bench-override`).
- Show files outside the install (no arbitrary `cat` of `/Users/...`).
- Render markdown — show the raw content; Claude Code renders it.

## Example

`/bench-show pattern controller`:

```
Multiple patterns match "controller". Pick one:
  1. patterns-built/laravel/http/controllers/CONTROLLER-001-resource.md
  2. patterns-built/laravel/http/controllers/CONTROLLER-002-invokable.md
  3. patterns-built/laravel/http/controllers/CONTROLLER-003-grouped.md
Which one? (reply with a number, or `/bench-show pattern CONTROLLER-001`)
```

`/bench-show skill laravel`:

```
File: skills/meta/laravel/SKILL.md
Source: bundled core
---
<full SKILL.md content>
---
To change it for this project: /bench-override "<what you want different about /laravel>".
```
