---
description: Add a single Bench addon to this project from inside Claude and run only its onboarding — install the addon, interview just the concerns it introduces, write the matching .bench/ config, and rebuild. Use on "/bench-addon-add", "add the bench-plan addon", "install the spatie-permission addon", "add an addon and set it up". Does not touch concerns you've already configured.
argument-hint: "<addon name, e.g. bench-plan | spatie-permission> (omit to pick from a list)"
---

You're the **/bench-addon-add** skill. Add one addon and onboard **only** it — never re-run the project's existing concern interview. You own the interview (subagents can't ask the user).

The user's request: **$ARGUMENTS**

## Step 1: Resolve the addon
If `$ARGUMENTS` names an addon (a bundled name or a path), use it. Otherwise list the choices and ask which one with `AskUserQuestion`:
```bash
<PLUGIN_ROOT>/bin/bench addon available    # name + description of every bundled addon
```

## Step 2: Snapshot concerns, then install
Record the concern set **before** install so you can detect what the addon adds:
```bash
ls <PLUGIN_ROOT>/concerns/*.md 2>/dev/null     # BEFORE
<PLUGIN_ROOT>/bin/bench addon add <name>       # installs on documented defaults + rebuilds
ls <PLUGIN_ROOT>/concerns/*.md 2>/dev/null     # AFTER
```
The addon installs immediately on its documented defaults — nothing is overwritten — so the project is already usable even if onboarding is skipped.

## Step 3: Onboard only the new concerns
The **new** concern files (AFTER minus BEFORE) are the ones this addon introduced. For each, in `order`:
1. Read it. If `when:` is a shell test, run it; skip the concern if it fails.
2. If `detect:` is present, run it — its output is the suggested default.
3. **Ask the `questions`** with `AskUserQuestion` (bundle a concern's questions into one prompt; pre-fill `default`/detect). The user accepts the default or changes it; skipping is allowed.
4. **Delegate to `concern-runner`** (Task) with `{ concern_file, answers, project_root: cwd, defer_rebuild: true }`.

If the addon added no concerns, there's nothing to onboard — skip to Step 4.

## Step 4: Rebuild + report
If Step 3 wrote anything, run `<PLUGIN_ROOT>/bin/bench rebuild` once. Report: the addon installed, what was asked, what was written (`.bench/` config), and the addon's new `/<command>`s.

**Then tell the user to run `/reload-plugins`** — Claude Code registers an addon's skills/agents at plugin load, so the new commands aren't live in this session until reloaded. Make this the explicit final action.

## Notes
- Onboards **only** the added addon's concerns (the BEFORE/AFTER delta) — your already-configured concerns are never re-asked. To (re)configure an existing concern, use `/bench-configure <concern>`. To set up the whole project from scratch, use `/bench-init`.
- The CLI is `<PLUGIN_ROOT>/bin/bench` — the installed copy for this project; it self-delegates `addon`/`rebuild` to the bench source. Never guess a path or use another project's copy.
