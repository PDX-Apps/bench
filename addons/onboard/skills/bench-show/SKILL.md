---
name: bench-show
description: |
  Use this skill when the user wants to view the full content of a Bench
  pattern, skill, or agent — typically to understand it before deciding
  to override or customize it. Triggers on "/bench-show", "show me the
  controller pattern", "what's in /api", "view the vue-store skill", "open
  the migration agent". Pairs with /bench-list for discovery.
argument-hint: <type> <name>
---

# /bench-show

Show the full content of a Bench pattern, skill, or agent. Read-only.

The user's request: **$ARGUMENTS**

## Usage

```
/bench-show pattern <name>      # show a pattern file (e.g., controller, CTRL-001, model)
/bench-show skill <name>        # show a skill's SKILL.md (e.g., api, vue-component)
/bench-show agent <name>        # show an agent's .md (e.g., controller, vue-ui)
```

`<name>` is matched against the install's file/directory names:
- Patterns: file basename match against `{install}/patterns-built/**/*.md`. Multiple matches → list them and ask which.
- Skills: directory match against `{install}/skills/*/SKILL.md`.
- Agents: basename match against `{install}/agents/*.md`.

Matching is case-insensitive and substring-based — `/bench-show pattern controller` matches any pattern with "controller" in the filename.

## What this skill does

1. **Parse the arguments**: extract `<type>` and `<name>`.

2. **Resolve the install root**: `{project_root}/.claude/plugins/bench/`. Verify it exists.

3. **Find candidate file(s)**:

   **For patterns** — search `{install}/patterns-built/`:
   ```bash
   find {install}/patterns-built -name '*.md' -ipath "*${name}*" -not -name '_meta.yaml'
   ```

   **For skills** — search `{install}/skills/`:
   ```bash
   find {install}/skills -name SKILL.md -ipath "*${name}*"
   ```

   **For agents** — search `{install}/agents/`:
   ```bash
   find {install}/agents -name '*.md' -ipath "*${name}*"
   ```

4. **Handle the result**:
   - Zero matches: report "not found" + suggest `/bench-list <type>` to see what's available.
   - One match: read the file with the Read tool and display the full content. Include the resolved path at the top so the user knows what they're looking at.
   - Multiple matches: list the candidate paths and ask which one to show.

5. **After displaying**, append one or two short reminders:
   - `Source: {bundled core | bundled addon: bench-X | project-local at ./.bench/}`
   - `To customize this for your project: ask Claude to override it. /bench-add-{type} will fork it into ./.bench/ where it shadows the bundled version.`

## What this skill does NOT do

- Modify the file (use `/bench-add-pattern` / `/bench-add-skill` / `/bench-add-agent` for that, with the fork-and-modify intent).
- Show files outside the install (no arbitrary `cat` of `/Users/...`).
- Render markdown — just show the raw file content. Claude Code renders it.

## Example

For `/bench-show pattern controller`:

```
Multiple patterns match "controller". Pick one:

  1. patterns-built/laravel/controllers/CTRL-001-resource-controllers.md
  2. patterns-built/laravel/controllers/CTRL-002-grouped-controllers.md
  3. patterns-built/laravel/controllers/CTRL-005-invokable-controllers.md

Which one? (reply with a number, or `/bench-show pattern CTRL-001` for direct match)
```

For `/bench-show skill api`:

```
File: skills/api/SKILL.md
Source: bundled core

---
<full SKILL.md content here>
---

To customize: ask Claude to override /api. /bench-add-skill api "<what you want changed>"
will fork this into ./.bench/skills/api/SKILL.md where it shadows the bundled one.
```
