# bench-ci

An interview-driven, customizable **quality pipeline** that runs the project's own checks at lifecycle moments and reports GREEN/RED.

## What it ships
- **`/ci`** skill → the **`ci`** agent: runs a trigger's stages in declared order (shell commands and bench skills), stops at the first failure, and reports an actionable diagnosis — never raw output. The `ci` agent is delegatable, so other addons can run the pipeline without duplicating it.
- **CI-001** pattern — how to run a pipeline well: fixer-before-checker, stop-on-first-failure, change-awareness, scoping, and how to diagnose PHPStan / Pest / tsc / ESLint failures down to the smallest fix.
- **`ci` concern** + **`config/ci.example.yaml`** — a setup interview that captures the project's pipeline into `.bench/ci.yaml`. The example file is the canonical annotated schema with the full trigger/stage vocabulary.

## `.bench/ci.yaml`

The seeded default is the minimal, universally-available gate — Pint auto-format then tests. Everything richer is opt-in.

```yaml
triggers:
  on_done:
    - name: format
      run: "vendor/bin/pint"
      fix: true
    - name: test
      run: "php artisan test"
```

**Triggers** are lifecycle moments (`on_done` runs when all coding for a task is finished; `before_commit` and `before_start` are also available). Each trigger is an ordered list of **stages** — a `name` plus exactly one of `run:` (shell) or `skill:` (a bench skill/plugin like `code-review`, `/e2e-run`, `/docs`) — with optional `when_changed:` glob and `fix: true`.

The project owns this file. The agent runs exactly what's declared, never guessing or imposing a scope.

## Opt-in: the full pipeline

The setup interview can grow the pipeline toward a full chain: stronger gate (Pint + PHPStan + tests via preflight) → frontend checks → code review → Playwright e2e authoring and run → docs refresh. The interview surfaces install commands for any missing addon so the chain works end to end.

## Enforcement

The setup interview emits a **pasteable CLAUDE.md snippet** that tells Claude to run `/ci on_done` before reporting a task done. Bench never writes your CLAUDE.md.

## Install
```bash
bench addon add bench-ci
```
