---
concern: ci
title: CI / quality gate commands
order: 50
detect: grep -q '"test"' composer.json 2>/dev/null && echo "composer test" || echo "php artisan test"
questions:
  - id: format
    ask: "Command to auto-fix formatting (blank if none)?"
    default: "./vendor/bin/pint"
  - id: static
    ask: "Command for static analysis (blank if none)?"
    default: "./vendor/bin/phpstan analyse"
  - id: test
    ask: "Command to run the tests?"
    default: detect
  - id: frontend
    ask: "Frontend checks (lint/typecheck/test), space- or &&-joined (blank if none)?"
    default: ""
output: config:.bench/ci.yaml
---

## Apply

Write `.bench/ci.yaml` with the project's **exact, hard-defined** commands (no detection at run time):

```yaml
# .bench/ci.yaml — the project's quality gate, read by the ci agent
format: "{format}"        # auto-fix step (run first); omit if blank
static: "{static}"        # static analysis; omit if blank
test:   "{test}"          # the test suite
frontend: "{frontend}"    # optional frontend checks
```

Only include the keys the project actually has. The `ci` agent runs these in order (format → static → test → frontend) — it never guesses.
