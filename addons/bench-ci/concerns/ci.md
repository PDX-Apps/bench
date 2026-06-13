---
concern: ci
title: Quality pipeline (lifecycle gates & stages)
order: 50
detect: test -x vendor/bin/preflight && echo use-preflight || echo keep-baseline
questions:
  - id: baseline
    ask: "Set up a quality pipeline that runs when coding is done? Bench seeds a safe default for a stock Laravel app: format with Pint, then run the test suite. Accept this baseline, or skip setup?"
    options: [accept-baseline, skip]
    default: accept-baseline
  - id: gate_upgrade
    ask: "Upgrade to a stronger gate? Replace the Pint+test baseline with a single self-gating gate — e.g. Preflight (format + static analysis + tests, on changed files only). Needs the preflight addon if not already installed; the suggested answer reflects whether it's detected."
    options: [keep-baseline, use-preflight]
    default: detect
  - id: full_pipeline
    ask: "Go further and build a full polished pipeline? Pick the extra stages to append after the gate. Any whose addon isn't installed yet will be reported with the exact command to add it."
    options: [code-review, playwright-e2e, e2e-run, docs]
    multi: true
    default: ""
  - id: extra_triggers
    ask: "Add lifecycle triggers beyond 'when done coding'? (default: just on_done)"
    options: [before_start, before_commit]
    multi: true
    default: ""
output: config:.bench/ci.yaml
---

## Apply

Write `.bench/ci.yaml` — the project's quality pipeline, read by the `ci` agent. Match the schema at
`<PLUGIN_ROOT>/config/ci.example.yaml`: a `triggers:` map, each trigger an ordered list of stages
(`name` + `run`|`skill` + optional `when_changed`/`fix`).

Assemble `triggers.on_done` from the answers, in this order:

1. **Gate.**
   - `gate_upgrade = use-preflight` → one stage:
     ```yaml
     - name: gate
       run: "vendor/bin/preflight --changed"
     ```
   - else (baseline) → two stages:
     ```yaml
     - name: format
       run: "vendor/bin/pint"
       fix: true
     - name: test
       run: "php artisan test"
     ```
2. **Full-pipeline stages** — append one per checked `full_pipeline` option, in this fixed order:
   - `code-review`  → `- {name: review, skill: "code-review"}`
   - `playwright-e2e` → `- {name: e2e-author, skill: "/playwright update the flows touched by this change"}`
   - `e2e-run`      → `- {name: e2e-run, skill: "/e2e-run"}`
   - `docs`         → `- {name: docs, skill: "/docs"}`
3. **Extra triggers** — `extra_triggers` is a list; for each checked option add that trigger (omit the
   whole step if the list is empty):
   - `before_commit` → seed one stage: `- {name: gate, skill: "/ci on_done"}` (re-runs the on_done gate).
   - `before_start` → seed a commented placeholder matching `<PLUGIN_ROOT>/config/ci.example.yaml`, e.g.
     ```yaml
     before_start:
       # - name: sync
       #   run: "git fetch && git status"
     ```

If `baseline = skip`, write nothing and report that no pipeline was configured.

### Also emit (in the concern-runner's report to the user — not files it writes silently)

- **The CLAUDE.md snippet** to paste in (bench never writes the user's CLAUDE.md). Render it from the
  chosen `on_done` stages, in order. Shape:
  ```markdown
  ## Quality pipeline — run before reporting a task done

  When all coding for a task is complete (before committing or reporting it done — NOT after every
  file), run this project's pipeline in order, stopping to fix any failure before continuing:

  1. {stage label} — `{run command}`        (for run: stages)
  2. {stage label} — run {skill}            (for skill: stages)
  ...

  Do not report the task done until the pipeline is green. (Or run `/ci` to drive it.)
  ```
- **Missing-addon install commands.** A `skill:` stage needs its addon installed. For each chosen
  full-pipeline option whose addon isn't present, list the exact command to add it:
  - `code-review` → the project's code-review plugin (note if it's external, not a bench addon)
  - `playwright-e2e` → `playwright` addon
  - `e2e-run` → `bench-e2e` addon
  - `docs` → `bench-docs` addon
  - `use-preflight` → `preflight` addon (if `vendor/bin/preflight` is absent)

  Detect presence by checking the installed plugin (e.g. the skill/command exists) or
  `<PLUGIN_ROOT>/.install-addons-config`. Surface, per missing addon, the single-addon add command —
  e.g. `/bench-addon-add bench-docs` — so the user ends with the complete working chain.

## Rules

- **Order = gate → full-pipeline stages (in the fixed order above) → assemble triggers.** Omit anything
  the user didn't choose — never pad the pipeline.
- The seeded default is the **minimal, universally-available** gate (Pint + `artisan test`); everything
  richer is opt-in.
- These are **suggestions, not a mandated scope** — the user owns `.bench/ci.yaml`. The baseline just
  saves typing. See `<PLUGIN_ROOT>/patterns-built/ci/CI-001-quality-gate.md`.
