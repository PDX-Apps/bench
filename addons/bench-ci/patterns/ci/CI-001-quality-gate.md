# Quality pipeline — how to run it well

The pipeline runs the project's **own** checks at the right lifecycle moment and reports a clean
GREEN/RED. *What* the stages are is the project's call (declared in `.bench/ci.yaml`); *how* you run
and report them is the same everywhere — that's this pattern.

## The project defines the pipeline; you just run it

`.bench/ci.yaml` holds named **triggers** (`on_done` is the common one — all coding for a task is
finished), each an **ordered list of stages**. A stage is a `name` plus exactly one of:

- **`run:`** — a shell command (`vendor/bin/pint`, `php artisan test`, a bespoke script), or
- **`skill:`** — a bench skill / plugin to invoke (`code-review`, `/e2e-run`, `/docs`, `/playwright …`).

A stage may carry an optional **`when_changed:`** glob and an optional **`fix: true`**. The project owns
the list — one stage or ten. Never substitute, reorder, or invent stages. The annotated schema lives at
`<PLUGIN_ROOT>/config/ci.example.yaml`.

## Recommended default (a suggestion, not a rule)

A stock Laravel app ships with just two things you can rely on, so the seeded `on_done` default is:

1. **Format — auto-fix** (`vendor/bin/pint`, `fix: true`). Run first so later stages see clean code.
2. **Tests** (`php artisan test`).

That's the safe baseline. Richer pipelines build on it, typically in this order:

3. **A stronger gate** — e.g. `vendor/bin/preflight --changed` (format + static + tests, self-gating).
4. **Frontend checks** — lint / type-check / affected-package tests, when the project has a frontend.
5. **Code review** — run the review plugin on the change.
6. **End-to-end** — author/refresh Playwright flows for what changed, then run the e2e suite.
7. **Docs** — refresh documentation for the change.

This is what the setup interview offers; `.bench/ci.yaml` decides. The pattern recommends; the project owns.

## Change-awareness is the tool's job

Don't reinvent change-detection. Prefer commands that self-gate (`preflight --changed` skips when
nothing changed; turbo/nx run only affected). Use `when_changed:` only as a thin hint for tools that
don't self-gate — evaluate the glob against the diff (`git diff --name-only` + staged) and skip the
stage when nothing matches. Omit it for "always run".

## Running discipline

- **Fixers before checkers.** A `fix: true` stage runs first and may modify files; surface the diff.
- **Run stages in declared order; stop at the first failure.** Fix it, re-run from there.
- **A `skill:` stage** is run by invoking that skill/plugin; a non-clean result fails the pipeline just
  like a non-zero shell exit. Let the skill own its own scope.
- **Scope where the command supports it.** Narrow a test/static command to changed files only if the
  declared command accepts it — never rewrite the command.
- **Honor `only`.** If asked for a single stage (`only: static`), run just that one.

## Diagnose — don't dump

Never paste raw tool output. Read it, find the root cause, report the **smallest fix**:

- **PHPStan / Larastan** → `file:line`, the rule, the actual type mismatch ("`?User` where `User`
  expected — guard the null or narrow the type"). Distinguish a real bug from a missing annotation.
- **Pest / PHPUnit** → the failing test name + assertion (expected vs actual), pointing at the line in
  the *code under test*.
- **tsc** → `file:line` + the type error in plain terms.
- **ESLint / Pint / Prettier** → if a fixer resolved it, say so; else name the rule + the fix.
- **A `skill:` stage** → relay that skill's own verdict (the review finding, the failing e2e flow).

## Report

End with a clear verdict:

```
CI: GREEN ✓        (or  RED ✗)
Trigger: on_done
Auto-fixed: {what the fixers changed, or "nothing"}
Stages: {stage} ✓ · {stage} ✓ · {stage} ✗
Failure: {the one that broke + the smallest fix}   ← only when RED
```

A task isn't done until the pipeline is GREEN. Never report GREEN with a failing stage.
