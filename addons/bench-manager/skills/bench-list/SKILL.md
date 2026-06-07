---
description: |
  Discover what's available in Bench — patterns, skills, agents — both bundled
  defaults and project-local overrides under ./.bench/. Use on "/bench-list",
  "what patterns are there", "show me the skills", "list bench agents", "what can
  I customize", "what's bundled". Pairs with /bench-show to view an item's body.
argument-hint: "[patterns|skills|agents] [filter]"
---

You're the **/bench-list** skill. Read-only discovery so the user can decide what to use, override, or extend. No writes, no network.

The user's request: **$ARGUMENTS**

## Modes

- `/bench-list` — summary of all three categories with counts
- `/bench-list patterns` — pattern files (grouped: `laravel` / `frontend/{vue,react}` / `authoring` / addon-contributed)
- `/bench-list skills` — slash commands (grouped: bundled core / bundled addon / project-local)
- `/bench-list agents` — worker agents (same groupings)
- append a fuzzy filter: `/bench-list patterns controller`, `/bench-list skills vue`

## Steps

1. **Resolve the install root** — `{project_root}/.claude/plugins/bench/`. Verify it exists.
2. **List per the argument:**
   - **patterns** — `find {install}/patterns-built -name '*.md' -not -name '_meta.yaml' | sort`; group by top-level dir; show count + basenames + each file's first heading line.
   - **skills** — `ls -d {install}/skills/*/`; for each, show the first `description:` line.
   - **agents** — `ls {install}/agents/*.md`; for each, show `name:` + first `description:` line.
3. **Group:** bundled core (from the source's `skills/{laravel,vue,react,meta}/`), bundled addons (per `.install-addons-config`), project-local (`{project_root}/.bench/`). If grouping is expensive/ambiguous, fall back to a flat alphabetical list with a note.
4. **Filter** (case-insensitive substring on the name) if provided.
5. **Output** a compact, scannable grouped list.

## What this skill does NOT do

- Show file contents — use `/bench-show <type> <name>`.
- Modify anything; reach the network.

## Example output (`/bench-list skills`)

```
Bundled core skills:
  Laravel: /laravel, /controller, /model, /migration, /event, /job, /policy, ...
  Vue:     /vue-component, /vue-page, /vue-store, /vue-ui, ...
  React:   /react-component, /react-page, /react-store, /react-ui, ...
  Meta:    /bench, /frontend, /help

Bundled addons:
  bench-manager: /bench-init, /bench-override, /bench-slice, /bench-list,
                 /bench-show, /bench-status

Project-local (./.bench/skills/):
  (none yet — create one with /bench-slice, or override a default with /bench-override)
```

## Reminders

End with one or two short pointers:
- `Tip: /bench-show <type> <name> to view its body`
- `Tip: change a default with /bench-override, or scaffold a domain with /bench-slice`
