---
description: Add a single Bench addon to this project from inside Claude and run only its onboarding — install the addon, interview the concerns it ships that aren't configured yet, write the matching .bench/ config, and rebuild. Use on "/bench-addon-add", "add the bench-plan addon", "install the spatie-permission addon", "add an addon and set it up". Does not touch concerns you've already configured.
argument-hint: "<addon name, e.g. bench-plan | spatie-permission> (omit to pick from a list)"
---

You're the **/bench-addon-add** skill. Add one addon and onboard **only** it — never re-run the project's existing concern interview. You own the interview (subagents can't ask the user).

The user's request: **$ARGUMENTS**

## Step 1: Resolve the addon
If `$ARGUMENTS` names an addon (a bundled name or a path), use it. Otherwise list the choices and ask which one with `AskUserQuestion`:
```bash
<PLUGIN_ROOT>/bin/bench addon available    # name + description of every bundled addon
```

## Step 2: Install, then identify the addon's OWN concerns
Snapshot the concern set first (a re-add of an already-installed addon adds nothing — see below), then install:
```bash
ls <PLUGIN_ROOT>/concerns/*.md 2>/dev/null     # BEFORE (newly-appeared concerns, if any)
<PLUGIN_ROOT>/bin/bench addon add <name>       # installs on documented defaults + rebuilds
```
The addon installs immediately on its documented defaults — nothing is overwritten — so the project is usable even if onboarding is skipped.

List **the addon's own concern files** (not the whole project's) — these are what this skill may onboard. They live in the addon's source `concerns/` dir:
```bash
# path addon → <path>/concerns/ ; bundled name → <bench-source>/addons/<name>/concerns/
src="$(cat <PLUGIN_ROOT>/.install-source)"     # bench source recorded at install
ls "$src/addons/<name>/concerns/"*.md 2>/dev/null   # (or "<path>/concerns/"*.md for a path addon)
```
Each concern's resolved copy is at `<PLUGIN_ROOT>/concerns/<name>.md` — read that for `when:`/`detect:`/`questions:`/`output:`.

## Step 3: Onboard the addon's concerns that AREN'T configured yet
Key rule: onboard by **whether the concern is configured**, not whether the concern file is new. A re-add (or an addon that arrived earlier as a dependency) has its concern already present but possibly never configured — still onboard it. For each of the addon's own concerns, in `order`:
1. Read it. If `when:` is a shell test, run it (from the project root); skip the concern if it fails.
2. **Skip if already configured:** if `output: config:.bench/<file>` and `{project_root}/.bench/<file>` already exists, it's set up — don't re-ask. (For an `output: overrides`/`vars` concern with no single marker file, only onboard it if it newly appeared this run — the BEFORE list above — so a re-add doesn't re-ask it.)
3. If `detect:` is present, run it — its output is the suggested default.
4. **Ask the `questions`** with `AskUserQuestion` (bundle a concern's questions; a `multi: true` question is a checklist → render as `multiSelect`, answer is a list; pre-fill `default`/detect). The user accepts the default or changes it; skipping is allowed.
5. **Delegate to `concern-runner`** (Task) with `{ concern_file, answers, project_root: cwd, defer_rebuild: true }`.

If every one of the addon's concerns is already configured (or it ships none), there's nothing to onboard — skip to Step 4.

## Step 4: Rebuild + report
If Step 3 wrote anything, run `<PLUGIN_ROOT>/bin/bench rebuild` once. Report: the addon installed, what was asked, what was written (`.bench/` config), and the addon's new `/<command>`s.

**Then tell the user to run `/reload-plugins`** — Claude Code registers an addon's skills/agents at plugin load, so the new commands aren't live in this session until reloaded. Make this the explicit final action.

## Notes
- Onboards **only** the added addon's own concerns, and only those **not yet configured** — your already-configured concerns are never re-asked, and an addon that was already installed but never set up (no `.bench/<config>` yet) still gets onboarded. To (re)configure any concern on demand, use `/bench-configure <concern>`. To set up the whole project from scratch, use `/bench-init`.
- The CLI is `<PLUGIN_ROOT>/bin/bench` — the installed copy for this project; it self-delegates `addon`/`rebuild` to the bench source. Never guess a path or use another project's copy.
