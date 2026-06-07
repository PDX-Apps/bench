# Concern declarations

A **concern** is a unit of project setup (auth, test framework, permissions, …) that **declares** its interview questions + exactly which patterns it affects — so setup is explicit and reliable, not guessed. Core ships `concerns/{name}.md` at the plugin root; addons ship `concerns/{name}.md`. `bench-init` and `/bench-configure` discover and run them.

## File format — `concerns/{name}.md`

Frontmatter declares the structured parts; the body is the apply instructions.

```markdown
---
concern: test-framework          # id (matches the filename)
title: Test framework            # display name
order: 20                        # interview order (lower runs first)
when: always                     # always | a shell test (run the concern only if it exits 0)
detect: grep -q pestphp/pest composer.json && echo pest || echo phpunit   # optional: stdout suggests a default
questions:
  - id: framework
    ask: "Which test runner does this project use — Pest or PHPUnit?"
    options: [pest, phpunit]     # optional fixed choices
    default: detect              # 'detect' = the detect output; or a literal value
  - id: location
    ask: "Where do feature/unit tests live (e.g. tests/Feature, tests/Unit)?"
affects:                         # the patterns this concern reviews + updates (relative to patterns-built/)
  - laravel/testing/RUNNER-001-running-tests.md
  - laravel/testing/TEST-001-feature-tests.md
  - laravel/testing/TEST-002-unit-tests.md
output: overrides                # overrides | config:.bench/<file>.yaml
---

## Apply

Given the answers, write the `.bench/` outputs:

- **RUNNER-001** (append) — the run command: `pest` → `./vendor/bin/pest`; `phpunit` → `php artisan test`.
- **TEST-001 / TEST-002** (append) — the syntax (Pest `it()` closures vs PHPUnit class methods) + the `{location}`.

Be explicit: one bullet per affected pattern, with the mode and the content to write.
```

## Conventions

- **One concern per file**; `concern:` id matches the filename.
- **`affects` is the contract** — list EVERY pattern the concern owns. This is the reliability win: the runner updates *all* of them (not whichever the scanner happened to notice).
- **Questions are explicit, never inferred.** `detect` only *suggests* a default; the user confirms.
- **`output`:**
  - `overrides` → write `.bench/patterns/...` overrides (by mode: append/replace) to the affected patterns. `.bench/` is auto-discovered (no manifest needed); rebuild materializes them.
  - `config:.bench/<file>.yaml` → write a structured config that the owning addon's agent reads (e.g. `ci` → `.bench/ci.yaml`, no detection at run time).
- **The Apply body is the runner's instructions** — be concrete (which override file, which mode, exact content). The `concern-runner` follows it.
