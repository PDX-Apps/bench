---
name: bench-list
description: |
  Use this skill when the user wants to discover what's available in Bench
  — patterns, skills, agents — both bundled defaults and project-local
  overrides. Triggers on "/bench-list", "what patterns are there", "show me
  the skills", "list bench agents", "what can I customize", "what's
  bundled". Pairs with /bench-show for viewing a specific item's body.
argument-hint: "[patterns|skills|agents]"
---

# /bench-list

List what's available in this Bench install so the user can decide what to use, override, or extend.

The user's request: **$ARGUMENTS**

## Modes

- `/bench-list` — top-level summary of all three categories with counts
- `/bench-list patterns` — list pattern files (grouped: laravel / frontend / onboarding / addon-contributed)
- `/bench-list skills` — list slash commands (grouped: bundled core / bundled addon / project-local)
- `/bench-list agents` — list worker agents (same groupings)

Optional fuzzy filter:
- `/bench-list patterns controller` — only patterns matching "controller"
- `/bench-list skills vue` — only skills matching "vue"

## What this skill does

Read-only discovery — no code generation, no file writes. Steps:

1. **Resolve the install root**: the Claude Code plugin lives at `{project_root}/.claude/plugins/bench/`. Verify it exists.

2. **List based on the argument**:

   **For patterns** — walk `{install}/patterns-built/` recursively:
   ```bash
   find {install}/patterns-built -name '*.md' -not -name '_meta.yaml' | sort
   ```
   Group output by top-level directory (`laravel/`, `frontend/vue/`, `frontend/react/`, `onboarding/`, plus any addon-contributed groups). Show file count per group plus the file basenames.

   **For skills** — list `{install}/skills/*/`:
   ```bash
   ls -d {install}/skills/*/
   ```
   Each subdir is a slash command. For each, read the first `description:` line from the SKILL.md frontmatter (with `head -20` + `grep -A 1 '^description:'`) and show as a single-line summary.

   **For agents** — list `{install}/agents/*.md`:
   ```bash
   ls {install}/agents/*.md
   ```
   For each, extract `name:` and the first `description:` line from frontmatter.

3. **Group output**:
   - **Bundled core** — names that match the source's `skills/laravel/*/`, `skills/vue/*/`, etc. at `{bench_source}/skills/{group}/` (read `{install}/.install-source` to find bench_source).
   - **Bundled addons** — anything in the install whose source is `{bench_source}/addons/{addon}/skills/`. Use the `.install-addons-config` file to know which addons are registered.
   - **Project-local** — anything from `{project_root}/.bench/skills/` or `agents/`.

   If grouping is ambiguous or expensive, fall back to a flat alphabetical list with a note.

4. **Apply the optional filter** if provided — case-insensitive substring match on the name.

5. **Output format** — a compact table or grouped list. Keep it scannable. For patterns specifically, show the file's first line (usually the heading) to give a sense of what it covers.

## What this skill does NOT do

- Show file contents — use `/bench-show <type> <name>` for that.
- Modify anything.
- Reach out to the network or external systems.

## Example output

For `/bench-list skills`:

```
Bundled core skills (60):
  Laravel (32): /api, /controller, /model, /migration, /event, /job, /policy, ...
  Vue     (12): /vue-component, /vue-page, /vue-store, /vue-ui, ...
  React   (12): /react-component, /react-page, /react-store, /react-ui, ...
  Meta     (4): /orchestrate, /help, /ci, /mcp-tools

Bundled addons:
  bench-onboard: /bench-onboard, /bench-update-claudemd, /bench-add-pattern,
                 /bench-add-skill, /bench-add-agent, /bench-add-domain,
                 /bench-audit, /bench-list, /bench-show

Project-local (./.bench/skills/):
  (none yet — add custom skills with /bench-add-skill)

Tip: see what a skill does with /bench-show skill <name>.
     Override a bundled skill by talking to Claude — say what you want changed
     and /bench-add-skill will fork the bundled one into ./.bench/.
```

## Reminders for the user

End the output with one or two short reminders pointing to next steps:

- `Tip: /bench-show <type> <name> to view body`
- `Tip: override any bundled default by telling Claude what you want changed — /bench-add-pattern, /bench-add-skill, or /bench-add-agent will fork it`
