---
description: Run the quality pipeline before pushing — code review of the changes, the CI gate, and optionally e2e — and report go/no-go. Use on "/quality", "review before I push", "is this ready to ship", "run the quality checks".
argument-hint: "[optional: --no-e2e | --only=review|ci|e2e]"
---

You're the **/quality** skill — the pre-push pipeline. Orchestrate the stages, then report a clear GO / NO-GO. You don't fix things; you surface what's wrong.

The arguments: **$ARGUMENTS**

## Step 0: Config (optional)
Read `{cwd}/.bench/quality.yaml` if present. It may define:
```yaml
pre:   ["git fetch origin", "..."]   # commands to run first (env/branch checks)
stages: [review, ci, e2e]            # which stages to run (default: review, ci)
post:  ["..."]                       # commands to run after the gate is GREEN, before push
```
Defaults if absent: stages = `review, ci` (add `e2e` only if configured or requested). Honor `--only=`/`--no-e2e`.

## Step 1: Scope
`git diff --name-only HEAD` (+ staged). If there are no changes, say so and stop.

## Step 2: Run the stages (in order; stop reporting NO-GO on the first hard failure)
- **pre** — run the configured pre-commands; abort if any fails.
- **review** → Task `subagent_type: "quality-reviewer"` with the diff/scope. Collect findings by severity.
- **ci** → Task `subagent_type: "ci"` (from bench-ci) with the changed scope. Collect GREEN/RED + diagnosis.
- **e2e** (if enabled) → Task `subagent_type: "e2e"` (from bench-playwright) for the affected flow(s).
- **post** — only if everything above passed: run the configured post-commands.

## Step 3: Report GO / NO-GO
```
Quality: {GO | NO-GO}
- Review:  {N blocking, M suggestions}
- CI:      {GREEN | RED — <failure>}
- E2E:     {passed | failed | skipped}
{blocking items, each with the smallest fix}
```
NO-GO if review has blocking findings or CI/e2e is RED. Don't push — that's the user's call.

## Notes
- `bench-ci` + `bench-playwright` are **dependencies** (auto-installed) — this skill delegates to their `ci` / `e2e` agents rather than reimplementing them.
