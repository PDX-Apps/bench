# Quality gate — how to run it well

The gate runs the project's **own** checks and reports a clean GREEN/RED. What the steps *are* is the project's call (declared in `.bench/ci.yaml`); **how** you run and report them is the same everywhere — that's this pattern.

## The project defines the steps; you just run them

`.bench/ci.yaml` holds an **ordered list of steps**, each a name + command (+ `fix: true` for auto-fixers). The project owns that list — one step or ten, `php artisan test` or a bespoke script. **Never substitute, reorder, or invent steps.** Run exactly what's declared, in declared order. The annotated schema lives at `<PLUGIN_ROOT>/config/ci.example.yaml`.

## Recommended baseline (a suggestion, not a rule)

Most projects' gates land on some subset of, in this order:

1. **Format / lint — auto-fix** (`fix: true`). Run first so later steps see clean code; report what changed.
2. **Static analysis** — types/lint that only reports.
3. **Tests** — the suite.
4. **Frontend checks** — lint / type-check / unit, when the project has a frontend.

This is what the `ci` concern pre-fills when setting a project up. It's a starting point the user edits — a project with only `php artisan test`, or with five custom steps, is equally valid. The pattern recommends; `ci.yaml` decides.

## Running discipline

- **Fixers before checkers.** A `fix: true` step runs first and may modify files; surface the diff so the user sees what was auto-fixed.
- **Stop at the first failure.** Don't run the rest of the gate once a step fails — fix that, re-run. (A formatter that *only reformats* isn't a failure; a checker exiting non-zero is.)
- **Scope where the command supports it.** When the run is verifying a focused change, narrow the test/static step to the changed files or a filter *if the declared command accepts it* — never rewrite the command itself.
- **Honor `only`.** If the caller asked for a single step (`only: static`), run just that one.

## Diagnose — don't dump

Never paste raw tool output. Read it, find the root cause, report the **smallest fix**:

- **PHPStan / Larastan** → `file:line`, the rule, and the actual type mismatch ("`?User` passed where `User` expected — guard the null or narrow the type"). Distinguish a real bug from a missing annotation.
- **Pest / PHPUnit** → the failing test name + the assertion (expected vs actual). Point at the line in the *code under test*, not just the test.
- **tsc** → `file:line` + the type error in plain terms.
- **ESLint / Pint / Prettier** → if a fixer resolved it, say so; if a remaining error needs a human, name the rule and the fix.

## Report

End with a clear verdict:

```
CI: GREEN ✓        (or  RED ✗)
Auto-fixed: {what the fixers changed, or "nothing"}
Steps: {step} ✓ · {step} ✓ · {step} ✗
Failure: {the one that broke + the smallest fix}   ← only when RED
```

A task isn't done until the gate is GREEN. Never report GREEN with a failing step.
