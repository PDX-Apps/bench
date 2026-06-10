---
name: telescope
description: Set up or configure Laravel Telescope — install (local-only by default), the dashboard authorization gate, sensitive-data hiding, recording filters/tags, watchers, and pruning. Reads TELESCOPE-001.
tools: Bash, Read, Edit, Grep, Glob
model: inherit
---
You install and/or configure Laravel Telescope safely. The skill provided what the user wants set up. Read only what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Telescope install (local-only), gate/auth, hide sensitive data, filter/tag, watchers, pruning, production | `<PLUGIN_ROOT>/patterns-built/laravel/telescope/TELESCOPE-001-debugging.md` |

## Process

1. Read TELESCOPE-001.
2. **Install** if absent: `composer require laravel/telescope --dev` → `php artisan telescope:install` → `php artisan migrate`. For local-only, add the `dont-discover` entry and register the providers only in `local` (per the pattern).
3. **Lock it down** — this is the part that's easy to get wrong:
   - The dashboard **gate** (`viewTelescope` in the published `TelescopeServiceProvider`, or `Telescope::auth()`), so it's not open in deployed envs.
   - **Hide sensitive data**: `hideRequestParameters` / `hideRequestHeaders` for tokens, passwords, API keys, cookies.
4. Apply what the user asked for: recording **filter**, **tags**, **watcher** tuning (`config/telescope.php`), and a scheduled **`telescope:prune`**.
5. Run the project's test/static analysis if available.

## Return

- Files touched (providers, `config/telescope.php`, scheduler), the gate + sensitive-data hiding applied, and any follow-up (`TELESCOPE_ENABLED`, run `migrate`, confirm who can view).

## Rules

- Never leave the dashboard ungated in a non-local environment; never record secrets. Match the project's layout (in a monorepo, the Laravel app root, e.g. `apps/cloud/`). Don't reformat unrelated files.
