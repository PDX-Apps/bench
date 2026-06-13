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
    multi: false                 # optional; true → checkbox prompt, answer is a LIST of picks
    default: detect              # 'detect' = the detect output; or a literal value
  - id: location
    ask: "Where do feature/unit tests live (e.g. tests/Feature, tests/Unit)?"
affects:                         # the patterns this concern reviews + updates (relative to patterns-built/)
  - laravel/testing/RUNNER-001-running-tests.md
  - laravel/testing/TEST-001-feature-tests.md
  - laravel/testing/TEST-002-unit-tests.md
output: overrides                # overrides | config:.bench/<file>.yaml | vars
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
- **`multi: true`** turns a question into a **multi-select checklist** — the skill renders it as an `AskUserQuestion` with `multiSelect`, and the answer reaches `concern-runner` as a **list** of the chosen `options` (empty list if none). Use it when the user can pick several at once (e.g. which optional pipeline stages to add). Default is single-select (one value). The `Apply` body must read the answer as a list and handle the empty case.
- **`output`:**
  - `overrides` → write `.bench/patterns/...` overrides (by mode: append/replace) to the affected patterns. `.bench/` is auto-discovered (no manifest needed); rebuild materializes them.
  - `config:.bench/<file>.yaml` → write a structured config that the owning addon's agent reads (e.g. `ci` → `.bench/ci.yaml`, no detection at run time). **Ship a canonical annotated schema** alongside it at `addons/<addon>/config/<file>.example.yaml`; the build copies it to `<PLUGIN_ROOT>/config/`, so the concern's `Apply` can say "match `<PLUGIN_ROOT>/config/<file>.example.yaml`" and the agent can read it as the schema. See [Config schemas](#config-schemas).
  - `vars` → merge each answer into the shared `.bench/vars.yaml` as `{question_id}: {value}`.
- **The Apply body is the runner's instructions** — be concrete (which override file, which mode, exact content). The `concern-runner` follows it.

## Config schemas

A concern with `output: config:.bench/<file>.yaml` should ship a **canonical annotated example** of that file so both the user and the reading agent have one source of truth for the shape:

- Put it at `addons/<addon>/config/<file>.example.yaml` — a fully-commented example with every key explained and realistic values.
- The build copies `config/*.example.{yaml,yml}` to `<PLUGIN_ROOT>/config/` (flat), the same way it copies `concerns/`.
- The concern's `Apply` body references it ("match `<PLUGIN_ROOT>/config/<file>.example.yaml`"), and the reading agent lists it in its Pattern Lookup as the schema. The committed `.bench/<file>.yaml` always wins; the example is the reference, not a default that's silently applied.

This keeps config files consistent and self-documenting as the system scales. Pattern files hold *HOW-to-do-it-well prose* (the same for every project); config files hold *this project's specific values*; the `.example.yaml` documents the config's shape.

## Build-time variables

For **project-tunable values that vary by layout** — chiefly paths, like where a project keeps its UI components — embed a variable placeholder in the addon's pattern/agent/skill text instead of hardcoding:

```
<!--bench:var:ui_dir;default:@/components/ui-->
```

At `bench build`, each placeholder resolves to the value from `.bench/vars.yaml` (if set) or its **inline default** — so the addon works out of the box with no config. To let the user set the value, ship a concern with `output: vars` whose **question ids are the variable names**; the answers merge into the one shared `.bench/vars.yaml`. A per-question `detect:` can auto-find the value (e.g. read `components.json` → `aliases.ui`), so the user usually just confirms.

**Variable names are shared across addons — never prefix with the addon name.** Two addons that both need the UI directory both use `ui_dir`; the user sets it once. Canonical names in use:

| Var                 | Default              | Meaning                                                 |
|---------------------|----------------------|---------------------------------------------------------|
| `ui_dir`            | `@/components/ui`    | UI-library components import path (shadcn / shadcn-vue) |
| `utils_dir`         | `@/lib/utils`        | `cn()` / utils helper import path                       |
| `inertia_pages_dir` | `resources/js/Pages` | Inertia page-component directory                        |

Reuse an existing name when it fits; add a new one only for a genuinely new concept, and list it here. Don't varify *example* paths that already use a portable `@/` alias (they adapt per project) — only addon-asserted concrete locations.
