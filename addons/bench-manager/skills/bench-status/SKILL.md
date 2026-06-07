---
description: |
  Synthesized status of the Bench install — versions, addons, project-local
  overrides, version drift, suggested next steps. Use on "/bench-status", "is
  bench set up correctly", "what's the state of bench", "did anything drift",
  "bench health check". A friendly wrapper around `bench status` that surfaces
  anomalies in plain language. Read-only.
---

You're the **/bench-status** skill. Synthesize the Bench install's status with drift checks and next steps. Read-only — never modify or rebuild; suggest commands, let the user run them.

## Steps

1. **Resolve the install root** — `{project_root}/.claude/plugins/bench/`. If missing: "Bench isn't installed here — run `bench build` from the source dir" and stop.
2. **Collect raw state:**
   ```bash
   {project_root}/.claude/plugins/bench/bin/bench status
   ```
   plus `{install}/.install-source`, `.install-versions-config`, `.install-addons-config`, and `.install-profile-config`.
3. **Project-side facts:** `{project_root}/.bench/` (present? how many overrides/skills/agents?), `composer.json` (Laravel+PHP) and `package.json` (vue/react) vs the persisted versions.
4. **Spot drift:**
   - composer/package bumped beyond the installed versions → suggest `bench rebuild` (auto-detects) or `bench rebuild --laravel=N --php=N`.
   - source `bin/bench` newer than the install → suggest `bench rebuild`.
   - `.bench/` present but never built into the active install → suggest `bench rebuild`.
   (A missing CLAUDE.md is NOT drift — bench doesn't own it.)
5. **Synthesize** ~15–25 scannable lines.

## Output template

```
## Bench install
  Source:        {bench source path}
  Install:       {project}/.claude/plugins/bench
  Versions:      Laravel {L}, PHP {P}, frontend = {vue|react|none}{, Vue V}
  Profile:       {standard | compact}
  Last rebuilt:  {age-relative or "unknown"}

## Project-local (./.bench/)
  Overrides:     {N patterns, M skills, K agents — or "none yet"}

## Bundled addons
  Loaded:        {names, or "(none)"}
  Available:     {bundled addons not yet loaded}

## Drift / anomalies
  {one bullet per issue, or "✓ none detected"}

## Suggested next steps
  {≤3 bullets, tailored to detected state}
```

## Example (drifted install)

```
## Bench install
  Versions:      Laravel 12, PHP 8.4, frontend = vue, Vue 3
  Profile:       standard
  Last rebuilt:  38d ago

## Project-local (./.bench/)
  Overrides:     none yet

## Bundled addons
  Loaded:        bench-manager
  Available:     laravel-boost

## Drift / anomalies
  ⚠️  composer.json now declares Laravel 13 + PHP 8.5; install still resolves L12 + PHP 8.4 patterns.

## Suggested next steps
  - bench rebuild        (picks up L13 + PHP 8.5 patterns)
  - /bench-init          (detect your conventions + set up .bench/ overrides)
```

## What this skill does NOT do

- Modify files, trigger a rebuild, or auto-load addons — it suggests commands; the user runs them.
- Probe the network.
