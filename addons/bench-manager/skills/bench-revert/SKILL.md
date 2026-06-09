---
description: |
  Remove a project-local Bench override and restore the bundled default. Use on
  "/bench-revert", "undo my controller override", "remove the .bench/ pattern for
  X", "drop the /resource skill override", "restore the bundled default for Y".
  Lists what's under ./.bench/, deletes the one you pick, and rebuilds.
argument-hint: "[optional: the override to remove, e.g. controller | CONTROLLER-001 | /resource]"
---

You're the **/bench-revert** skill. Remove one project-local override from `./.bench/` and rebuild so the bundled default takes over again. This is the inverse of `/bench-override` and `/bench-slice`. You only ever touch files **under `{project_root}/.bench/`** — never the bundled install, never project source.

The user's request: **$ARGUMENTS**

## Step 1: Inventory the project-local overrides
List what's removable under `{project_root}/.bench/`:
```bash
find {project_root}/.bench -type f \( -path '*/patterns/*' -o -path '*/skills/*' -o -path '*/agents/*' \) -name '*.md' | sort
ls {project_root}/.bench/*.yaml 2>/dev/null   # configs (ci.yaml, e2e.yaml, docs.yaml, vars.yaml, rendering.yaml, …)
```
Group them: **pattern overrides**, **skill overrides / slices**, **agent overrides / slices**, **configs**. If there's nothing, say so and stop ("No project-local overrides under ./.bench/ — nothing to revert").

## Step 2: Resolve the target
- If `$ARGUMENTS` names one, match it (case-insensitive substring) against the inventory.
  - One match → confirm it with the user (show the path + what reverting restores).
  - Multiple → list them and ask which.
  - Zero → show the inventory and ask.
- If `$ARGUMENTS` is empty → present the inventory and ask which to remove.

**Slice caveat:** a `/bench-slice` created a *triple* (skill + agent + pattern). If the target is one leg of a slice, point that out and offer to remove the whole triple or just the named file.

## Step 3: Remove + rebuild
1. Delete the chosen file(s) under `./.bench/`.
2. Rebuild so the change materializes:
   ```bash
   {project_root}/.claude/plugins/bench/bin/bench rebuild
   ```
   (For a `config` file like `.bench/ci.yaml`, removing it means the owning addon's agent has no config — note that the user may want to re-run `/bench-configure <concern>` rather than leave it unset.)

## Step 4: Report
State what was removed, that the bundled default (or addon behavior) is restored, and the rebuild result. If it was part of a slice and only one leg was removed, flag the now-orphaned legs.

## Notes
- **Scope-locked to `./.bench/`.** If the user asks to "revert" something that isn't a project-local override (a bundled file, project source), explain you only manage `.bench/` overrides — bundled defaults are changed with `/bench-override`, not edited in place.
- Deleting a `.bench/` file is fully reversible by re-creating it (`/bench-override`, `/bench-slice`, `/bench-configure`).
