---
name: bench-status
description: |
  Use this skill when the user wants a synthesized status of their Bench
  install — versions, addons, project memory, drift detection, suggested
  next steps. Triggers on "/bench-status", "is bench set up correctly",
  "what's the state of bench", "did anything drift", "bench health check".
  Friendlier wrapper around `bench status` that surfaces anomalies and
  suggests next moves in plain language.
---

# /bench-status

Synthesize a Bench install's status with project-specific context, drift checks, and suggested next steps. Read-only.

## What this skill does

1. **Resolve the install root**: `{project_root}/.claude/plugins/bench/`. If missing, report "Bench isn't installed in this project — run `bench init` from the source dir to get started" and stop.

2. **Collect raw state** (run via Bash):

   ```bash
   {project_root}/.claude/plugins/bench/bin/bench status
   ```

   Plus quick state file reads:
   - `{install}/.install-source` — bench source location
   - `{install}/.install-versions-config` — persisted version flags
   - `{install}/.install-addons-config` — registered addons

3. **Check project-side facts**:
   - `{project_root}/CLAUDE.md` — exists? When was it last modified vs. the install?
   - `{project_root}/.bench/` — exists with a manifest?
   - `{project_root}/composer.json` — Laravel + PHP versions; compare to persisted versions
   - `{project_root}/package.json` — Vue/React presence; compare to persisted frontend

4. **Spot drift**:
   - Composer or package.json bumped beyond the installed version → suggest `bench rebuild --laravel=N --php=N` (or just `bench rebuild` for auto-detect).
   - Bench source `bin/bench` newer than the install's bench → suggest a plain `bench rebuild`.
   - `.bench/` present but never been built into the active install → suggest `bench rebuild`.
   - CLAUDE.md doesn't exist → suggest `/bench-onboard` or `/bench-update-claudemd`.

5. **Synthesize the output** in a compact, scannable format. Aim for ~15-25 lines.

## Output template

```
## Bench install

  Source:           {bench source path}
  Install:          {project}/.claude/plugins/bench
  Versions:         Laravel {L}, PHP {P}, frontend = {vue|react|none}{ ", Vue " + V if vue}
  Last rebuilt:     {age-relative or "unknown — no rebuild record"}

## Project memory

  CLAUDE.md:        {present, last modified Xd ago | MISSING — agents fall back to defaults}
  .bench/ extension:{present + auto-discovered | none}

## Bundled addons

  Loaded:           {addon names, or "(none)"}
  Available:        {bundled addons not yet loaded}

## Drift / anomalies

  {one bullet per detected issue, or "✓ none detected"}

## Suggested next steps

  {tailored to detected state — at most 3 bullets}
```

## Example outputs

**Healthy install, fresh project:**

```
## Bench install

  Source:    /Users/x/repos/bench
  Install:   /Users/x/my-app/.claude/plugins/bench
  Versions:  Laravel 13, PHP 8.5, frontend = vue, Vue 3
  Last rebuilt: 4h ago

## Project memory

  CLAUDE.md: present, last modified 2d ago
  .bench/ extension: none

## Bundled addons

  Loaded:    bench-onboard
  Available: laravel-boost

## Drift / anomalies

  ✓ none detected

## Suggested next steps

  - Try /boost-install if you want database-schema + tinker + search-docs MCP tools (`bench addon add laravel-boost`).
  - Run /bench-onboard once if you haven't tailored CLAUDE.md and pattern overrides yet.
```

**Drifted install:**

```
## Bench install

  Source:    /Users/x/repos/bench
  Install:   /Users/x/my-app/.claude/plugins/bench
  Versions:  Laravel 12, PHP 8.4, frontend = vue, Vue 3
  Last rebuilt: 38d ago

## Project memory

  CLAUDE.md: MISSING — agents fall back to defaults

## Bundled addons

  Loaded:    (none)
  Available: bench-onboard, laravel-boost

## Drift / anomalies

  ⚠️  composer.json now declares Laravel 13 + PHP 8.5; install is still resolving Laravel 12 + PHP 8.4 patterns.
  ⚠️  No CLAUDE.md at the project root; every agent invocation uses generic defaults.

## Suggested next steps

  - bench rebuild               (auto-detects current composer/package versions; picks up L13 + PHP 8.5 patterns)
  - bench addon add onboard     (gives you /bench-onboard, /bench-add-pattern, etc.)
  - After onboard is loaded: /bench-onboard  to scaffold CLAUDE.md
```

## What this skill does NOT do

- Modify any files. Read-only.
- Trigger a rebuild automatically. It suggests the command; the user runs it.
- Auto-load addons. Suggests `bench addon add NAME`; user confirms.
- Probe network or external systems.
