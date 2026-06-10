---
description: Verify, auto-fix, or configure PHP code quality with Preflight (format, lint, static analysis, tests). Use after changing PHP files and before reporting done, OR when the user wants to set up / adjust Preflight — choose steps, coverage gates, excluded paths, module scoping, or flags.
argument-hint: [run scope ("the files I changed" (default) | a path | "whole project") OR a config change]
---

You're the **/preflight** skill. Delegate to the `preflight` agent — it runs the fix/recheck loop (or edits `preflight.php`) in isolation so the work stays out of this conversation. You don't run it yourself.

The request: **$ARGUMENTS**

## Step 1: Classify + scope

- **Run** (default) — verify/fix changes. Scope: default = working-tree changes (`--dirty`); a path/file → `--files=<path>`; "whole project" → no `--dirty`; "since main"/CI → `--since=<ref>`; a module → `--module=<Name>`.
- **Configure** — the user wants to change `preflight.php`: choose steps (`withSteps`/`addSteps`/`tune`/`without`), coverage gates (`Tests::make()->minCoverage/minPatchCoverage`), `exclude([...])` paths, `withModules(...)`, or a per-step option. Pass the desired change through.

## Step 2: Resolve

- Confirm Preflight is set up: `vendor/bin/preflight` (config is optional — it's zero-config). If absent, tell the user to `composer require --dev pdxapps/preflight` then `vendor/bin/preflight install` — don't fake the checks.
- In a monorepo, work from the Laravel app root (e.g. `apps/cloud/`). For a modules layout (nwidart), prefer `--module=<Name>` / `->withModules(...)`.

## Step 3: Delegate

Task tool, `subagent_type: "preflight"`, pass the scope.

## Step 4: Report

Relay what the agent fixed (grouped by file) and the final exit status (`0` = clean). If it stopped to ask — e.g. a patch-coverage threshold it couldn't legitimately meet — surface that decision to the user rather than papering over it.

## Not covered by a pattern?

If the request needs a **preflight** capability this addon's pattern doesn't cover (an advanced flag or config option), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "preflight" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
