---
description: Set up or configure Laravel Telescope (the local debug dashboard) — install, the viewTelescope authorization gate, hiding sensitive request data, recording filters/tags, watcher tuning, and pruning. Use when the user mentions Telescope, a debug dashboard, gating Telescope, or hiding sensitive data from it.
argument-hint: [what to set up — e.g. "install local-only + gate to admins + prune daily"]
---

You're the **/telescope** skill. Turn the request into an enriched delegation to the `telescope` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Is this a first **install**, or **configuring** an existing setup?
- What to lock down / change: the dashboard **gate** (who can view — an `isAdmin()` user, a role, token/IP), **sensitive data** to hide, recording **filter** (e.g. failed/slow only in prod), **watchers** to tune, **pruning** schedule.

## Step 2: Resolve
- Telescope not installed and the user wants config → install first (local-only by default).
- Gate audience unclear → ask who should view the dashboard (it exposes everything).
- Detect the Laravel app root (in a monorepo, e.g. `apps/cloud/`) so the agent edits the right providers/config.

## Step 3: Build context blob
```
- Action: install | configure
- Gate: viewTelescope → {isAdmin() | role | Telescope::auth token/IP}
- Hide: [authorization header, _token, password]
- Filter: {local: all; prod: failed/slow/monitored}
- Prune: telescope:prune --hours=48 daily
```

## Step 4: Delegate
Task tool, `subagent_type: "telescope"`, pass the blob.

## Step 5: Synthesize
Report what was installed/changed (providers, `config/telescope.php`, scheduler), the gate + sensitive-data hiding, and follow-ups (`php artisan migrate`, `TELESCOPE_ENABLED`).

## Not covered by a pattern?

If the request needs a **laravel-telescope** capability this addon's pattern doesn't cover (a specific watcher option or advanced feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-telescope" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
