# laravel-boost

Makes Bench agents aware of [laravel/boost](https://github.com/laravel/boost) — an MCP server that gives AI assistants direct access to Laravel internals (database schema, tinker, routes, artisan commands, semantic docs search, and more).

**Status:** opt-in bundled addon. Install with `bench addon add laravel-boost`.

---

**Contents:** [Why this matters](#why-this-matters) · [Install](#install) · [Commands](#commands) · [What gets installed](#what-gets-installed) · [Tools provided by Boost](#tools-provided-by-boost) · [Safety](#safety)

---

## Why this matters

Without Boost, agents working on a Laravel project read migrations to guess at the current schema, parse `php artisan route:list` output to find routes, and grep config files instead of seeing resolved values. All of that drifts from reality — migrations show order of changes (not current state), `.env` overrides config files, custom artisan commands need discovery.

With Boost installed, agents have structured MCP tools that return current state of the running app: `database-schema`, `list-routes`, `get-config`, `tinker`, `last-error`, `search-docs`, and others. This addon does two things:

1. Ships an **awareness pattern** that tells worker agents which Boost tool to prefer over which filesystem/artisan equivalent
2. Ships a **`/boost-install` slash command** that walks through installing Boost in your project with explicit permission at each state-modifying step

---

## Install

```bash
# From any project with bench installed:
bench addon add laravel-boost
```

That registers the addon and rebuilds. After that, run the install skill in Claude Code:

```
/boost-install
```

The skill walks through:

1. Resolve your Laravel root (auto-detect or `--laravel-root=PATH`)
2. Check existing state (is Boost already installed? MCP entry present?)
3. Ask permission, then `composer require laravel/boost --dev`
4. Ask permission, then `php artisan boost:install`
5. Verify the MCP server is registered in `.mcp.json` (offers to add it if missing)
6. Optionally append a short Boost section to your `CLAUDE.md`

After install, restart Claude Code so the MCP server connects. The next agent invocation will have access to all `mcp__laravel-boost__*` tools.

### Skip parts

```
/boost-install --no-mcp          # composer install + boost:install only, skip MCP verification
/boost-install --no-claude-md    # don't append the awareness section to CLAUDE.md
/boost-install --laravel-root=apps/api   # explicit Laravel root (monorepos)
```

---

## Commands

| Command | Purpose |
|---|---|
| `/boost-install` | One-time setup: composer install + artisan install + MCP registration with permission prompts |

---

## What gets installed

This addon contributes:

- **1 pattern** at `patterns-built/laravel/boost-awareness.md` — guidance for worker agents on which Boost tool to use when
- **1 skill** at `skills/boost-install/SKILL.md` — the `/boost-install` slash command
- **1 worker agent** at `agents/boost-installer.md` — performs the install workflow with user permission

The awareness pattern is automatically discoverable by any Laravel worker agent. If you have `CLAUDE.md` updated by `/boost-install`, agents are explicitly directed to prefer Boost tools.

---

## Tools provided by Boost

(After install — these come from laravel/boost itself, not from this addon.)

| Tool | Use it for | Prefer over |
|---|---|---|
| `application-info` | Stack snapshot — Laravel/PHP versions, env | reading `composer.json` + `.env` |
| `database-schema` | Current DB schema (tables, columns, types) | reading migration files |
| `database-query` | Read-only SELECT against the project DB | hand-writing Tinker for "what's in this table" |
| `database-connections` | List configured DB connections | grepping `config/database.php` |
| `tinker` | Execute PHP / Eloquent in Laravel context | scaffolding throwaway artisan commands |
| `list-routes` | Current route table with names, middleware, controllers | `php artisan route:list` + parsing |
| `list-artisan-commands` | Available artisan commands (incl. custom) | reading `app/Console/Commands/` |
| `get-config` | Resolved config value at a dotted key | reading config files (won't reflect env overrides) |
| `list-available-config-keys` | All addressable config keys | guessing |
| `list-available-env-vars` | Env vars the app reads | grepping for `env(` |
| `read-log-entries` | Recent log lines from `storage/logs/` | tailing files |
| `last-error` | Most recent exception with stack trace | hunting through logs |
| `search-docs` | Semantic search of Laravel docs (+ ecosystem packages) | guessing API surface from training data |
| `get-absolute-url` | Resolve named route or relative path to full URL | hand-building URLs |

Full details in [`patterns/laravel/boost-awareness.md`](./patterns/laravel/boost-awareness.md).

---

## Safety

The `/boost-install` skill enforces a few rules so it never surprises you:

- **Permission per step.** Composer install, artisan command, and `.mcp.json` edits each require an explicit "yes". "skip-all" stops the flow.
- **Production refuses.** If `APP_ENV=production`, the installer refuses the `boost:install` step.
- **No raw sed for settings files.** MCP-config merges use `python3` + the json module so existing entries survive.
- **Passes through Boost's prompts verbatim.** If `boost:install` is interactive (it often is — asks about Herd, etc.), you answer it, not the agent.
- **Stops on unexpected output.** Doesn't try to "auto-recover" by re-running with different flags.

---

## Remove

```bash
bench addon remove laravel-boost
```

Removing the addon takes the awareness pattern + skill + agent out of the install. It does **not** uninstall the `laravel/boost` composer package from your project — do that separately with `composer remove laravel/boost` if desired.

---

## See also

- [Laravel Boost on GitHub](https://github.com/laravel/boost)
- The awareness pattern this addon ships: [`patterns/laravel/boost-awareness.md`](./patterns/laravel/boost-awareness.md)
