# preflight

Verify and auto-fix PHP code quality with [`pdxapps/preflight`](https://github.com/PDX-Apps/preflight) — one command that runs the project's formatter, linter, static analysis, and tests behind a unified result schema with authoritative exit codes and an agent-friendly output format.

## What it ships

- **`/preflight`** skill + **`preflight`** agent — run the **fix → recheck** loop (`vendor/bin/preflight --fix --dirty --format=agent`) until the checks exit `0`, fixing the underlying issues (not suppressing them). The agent runs in isolation so the loop stays out of your main conversation.
- **`PREFLIGHT-001-checks`** pattern — the workflow + conventions: scope/format flags, the exit-code contract, patch-coverage handling (`Uncovered changed lines`), and `preflight.php` configuration.

## Install

```bash
bench addon add preflight
bench rebuild
```

The project itself needs Preflight (the addon teaches Bench to drive it):

```bash
composer require --dev pdxapps/preflight
vendor/bin/preflight install     # installs missing tools + scaffolds preflight.php
```

Then, after changing PHP:

```
/preflight                     # checks + fixes the files you changed
/preflight whole project       # or the full codebase
```

> Complements **bench-ci**: Preflight is the per-change quality gate during development; you can also list `vendor/bin/preflight` as a step in your `.bench/ci.yaml` for the CI gate.
