# bench-ci

A **quality gate** that runs the project's *own* declared checks — format, static analysis, tests, or whatever steps the project defines — and reports failures cleanly.

## What it ships
- **`/ci`** skill → the **`ci`** agent: runs the steps declared in `.bench/ci.yaml`, in order, stopping at the first failure; auto-fixes any `fix: true` step first; and reports an actionable diagnosis (not raw output). The `ci` agent is delegatable, so other addons can run the gate without duplicating it.
- **CI-001** pattern — how to run a gate well: the recommended baseline (format → static → test, + frontend if present), fixer-before-checker, stop-on-first-failure, scoping, and how to diagnose PHPStan / Pest / tsc / ESLint failures down to the smallest fix.
- **`ci` concern** + **`config/ci.example.yaml`** — at setup, captures the project's **gate steps** into `.bench/ci.yaml` (pre-filled with the common baseline, fully editable). The example file is the canonical annotated schema.

**The project owns its gate.** The steps are declared once in `.bench/ci.yaml` (`php artisan test`, `./vendor/bin/phpstan`, a bespoke script — anything); the agent runs exactly those, never guessing or imposing a scope.

## `.bench/ci.yaml`
```yaml
steps:
  - name: format
    run: "./vendor/bin/pint"
    fix: true
  - name: static
    run: "./vendor/bin/phpstan analyse"
  - name: test
    run: "php artisan test"
```
One step or ten — see `config/ci.example.yaml` for the full annotated reference.

## Install
```bash
bench addon add bench-ci && bench rebuild
```
