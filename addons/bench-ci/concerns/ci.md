---
concern: ci
title: CI / quality gate steps
order: 50
detect: grep -q '"test"' composer.json 2>/dev/null && echo "composer test" || echo "php artisan test"
questions:
  - id: format
    ask: "Auto-fix/format step — command (blank to skip). Suggested baseline; your gate is yours to shape."
    default: "./vendor/bin/pint"
  - id: static
    ask: "Static-analysis step — command (blank to skip)."
    default: "./vendor/bin/phpstan analyse"
  - id: test
    ask: "Test step — command to run the suite (blank to skip)."
    default: "php artisan test"
  - id: frontend
    ask: "Frontend-checks step — lint/typecheck/test, &&-joined (blank if none)."
    default: ""
  - id: extra
    ask: "Any other gate steps, one per line as 'name: command' (blank if none) — e.g. 'security: composer audit'. These run after the above, in the order given."
    default: ""
output: config:.bench/ci.yaml
---

## Apply

Write `.bench/ci.yaml` as an **ordered list of steps** — the project's gate, run by the `ci` agent exactly as written. The canonical annotated shape is `<PLUGIN_ROOT>/config/ci.example.yaml`; match it.

```yaml
# .bench/ci.yaml — the project's quality gate, read by the ci agent
steps:
  - name: format
    run: "{format}"
    fix: true
  - name: static
    run: "{static}"
  - name: test
    run: "{test}"
  - name: frontend
    run: "{frontend}"
  # plus one entry per line of {extra}, in order
```

Rules for assembling it:

- **Order = the order asked** (format → static → test → frontend → extras), but the list is the user's; **omit any step the user left blank** — don't pad the gate with steps they don't run.
- **`format` carries `fix: true`** (it's an auto-fixer). The others are checkers (no `fix` key). If an `extra` step is clearly a fixer, mark it `fix: true` too.
- **`extra`** — split on lines; each `name: command` becomes a step appended in order.
- Don't invent steps or commands the user didn't give. A one-step gate (`steps: [{name: test, run: "php artisan test"}]`) is valid.
- These are **suggestions, not a mandated scope** — the user decides what their gate is; the baseline just saves typing.
