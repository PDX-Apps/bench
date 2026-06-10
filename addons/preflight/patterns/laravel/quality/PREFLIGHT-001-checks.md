# PREFLIGHT-001 — Verifying PHP changes (Preflight)

`pdxapps/preflight` runs a project's PHP quality tools — formatter, linters, static analysis, mess detection, security audit, tests/coverage — through **one command** with one normalized output and an authoritative exit code. Each tool runs only if installed. It's **zero-config** (with no `preflight.php`, every installed default step runs); a `preflight.php` customizes the set.

## The run loop (the core agent workflow)

Verify — and auto-fix — your changes before reporting done. Loop until the exit code is `0`:

```bash
# 1. Auto-fix what's fixable, scoped to YOUR changes:
vendor/bin/preflight --fix --dirty --format=agent

# 2. Re-check, still scoped:
vendor/bin/preflight --dirty --format=agent
```

3. For each `file:line:col [tool] message`, open the file and fix the **underlying** issue (smallest correct change, no suppression). Repeat step 2 until it exits `0`.

- The **exit code is authoritative**: `0` = clean, non-zero = findings remain. Branch on it; never report success while a finding remains.
- `--format=agent` = errors only, no ANSI/no success noise — readable/greppable lines.

## Commands

`preflight` (no subcommand) == `preflight run`. The rest are setup/inspection:

| Command | What it does |
|---|---|
| `run` (default) | Run the checks (or fixes with `--fix`). |
| `doctor` | Installed tools, discovered config, active coverage driver, what would run. **Run this first** to understand a project. |
| `steps` | List configured steps + whether each tool is available. |
| `init` | Scaffold a `preflight.php`. |
| `install` | Preview + `composer require --dev` the tools the steps need (`--runner=`, `--with-phpmd`, `--yes`). |

## `run` flags

- **Mode**: `--fix` (apply fixes — Pint/PHPCBF/Rector/Composer-Normalize) · `--check` (force check-only over a fix-by-default config).
- **Scope**: *(none)* = whole project · `--dirty` = working-tree changes (`--all` overrides a dirty-by-default config) · **`--since=<ref>`** = changed since a git ref (what a PR/CI check uses, and what feeds **patch coverage**) · `--files=a.php,b.php` (positional paths work too) · `--module=Billing` (one module's `app`/`tests`, for `->withModules(...)` projects). Whole-only steps (composer-audit/-normalize, deptrac) **skip** under any narrowed scope.
- **Which steps**: `--only=phpstan,test` / `--skip=phpmd` (by the names `preflight steps` prints; mutually exclusive; unknown name = hard error).
- **Format** (`-f`/`--format=`): `agent` (parse this in a loop) · `human` · `json` · `github` (PR `::error`) · `sarif` · `markdown` · `auto` (human on a tty, agent when piped).
- **Extras**: `--write=FORMAT:PATH` (also render to a file) · `--report=PATH` · `--fail-fast` · `--skip-if-fresh` (skip if inputs unchanged since last pass).

## Configuration — `preflight.php`

Returns a fluent builder (namespaces `PdxApps\Preflight\Preflight` + `PdxApps\Preflight\Steps\{...}`):

```php
<?php

use PdxApps\Preflight\Preflight;
use PdxApps\Preflight\Steps\{Pint, Phpstan, Tests};

return Preflight::configure()
    ->withSteps([
        Pint::class,
        Phpstan::make()->level(9)->memoryLimit('1G'),
        Tests::make()->before(['php', 'artisan', 'config:clear']),
    ]);
```

**Choosing the step set** (use one): `->withSteps([...])` (exact set + order) · `->addSteps([...])` (keep defaults, append, e.g. opt-in `ComposerNormalize`/`Deptrac`) · `->tune(Foo::make()->...)` (reconfigure one default) · `->without(Foo::class)` (drop one).

**Run-wide**: `->withPaths([...])` · **`->exclude([...])`** (drop findings from paths **across every tool** — for framework scaffolding the analysers misjudge, e.g. `app/Providers`, `database`, `app/Legacy/*.php`) · **`->withModules(dir, app, tests)`** (enable `--module=` for `Modules/<Name>/app` layouts) · `->failFast()` · `->fixByDefault()` · `->dirtyByDefault()` · `->defaultFormat('agent')` · **`->forAgents()`** (bundles dirty + fix + agent format so a bare `preflight` does the right thing for an agent).

**Per-step** (common — full list in the package's `docs/steps.md`): `Phpstan::make()->level(0..9)->memoryLimit('1G')` · `Phpcs::make()->standard('PSR12')->parallel(4)` · `Psalm::make()->threads(4)` · `Phpmd::make()->rulesets([...])` · `ComposerAudit::make()->abandoned('report'|'ignore'|'fail')` · `Tests::make()->runner('auto'|'pest'|'phpunit'|'paratest')->filter(...)->before([...])`. Every step also has `->config(?path)`, `->before([...])`, `->args([...])` (raw-flag escape hatch).

**Precedence** (per setting): an explicit setter / `->args()` wins → else the tool's own config file (`phpstan.neon`, `pint.json`) → else the built-in default. **Never silently apply** security-relevant Composer changes (`allow-plugins`, `minimum-stability`) — those are the user's call. For the exhaustive reference, read `docs/configuration.md` + `docs/steps.md` in the package.

## Coverage gates (on the `Tests` step)

```php
Tests::make()
    ->coverage(['clover' => 'build/coverage.xml'])  // required for any gate
    ->minCoverage(80)         // whole-project line floor — never regress
    ->minPatchCoverage(90);   // 90% of the lines THIS change touched must be covered
```

Coverage needs a driver (PCOV/phpdbg/Xdebug) — `preflight doctor` shows it; without one, tests still run and the gate is skipped with a non-failing warning. `minPatchCoverage` also needs a change-scoped run (`--since`/`--dirty`) + a `clover` report; on a whole-project run it's inert.

## Patch-coverage findings (`Uncovered changed lines`)

A shortfall looks like `src/Order.php:42 [test] Uncovered changed lines: 42-45, 51` — lines **you changed** that no test exercises. Resolve in order:

1. **Write a test that covers them** — drive the **public** method that reaches the code; private methods are covered transitively.
2. **Genuinely untestable** line (environment-dependent branch, defensive `return` you can't reproduce) → exclude with a **bare** marker, reason on its own line above:

   ```php
   // Only reachable when the temp dir is unwritable — not reproducible in a test.
   // @codeCoverageIgnoreStart
   return Result::failure('cannot write');
   // @codeCoverageIgnoreEnd
   ```

3. **Unsure, or can't reach the threshold after a real attempt → STOP and ask the user.** Don't loop on contrived tests or blanket-ignore code. If the user agrees the target is too strict, lower it in `preflight.php` (`Tests::make()->minPatchCoverage(N)`) — a visible, reviewable decision — not a workaround.

## Rules

- Exit code is the source of truth — never green-wash a finding.
- `preflight doctor` first on an unfamiliar project. Scope with `--dirty` in dev, `--since=<ref>` for CI/patch-coverage.
- Fix the underlying issue; reserve `exclude()`/ignore markers for genuinely unfixable cases, with a reason. Never silently change security-relevant Composer settings.
