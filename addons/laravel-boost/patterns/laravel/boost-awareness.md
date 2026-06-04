# Laravel Boost (MCP) — awareness

Laravel Boost ships an MCP server that exposes structured Laravel tools to AI
agents. When Boost is installed in the project, prefer its tools over the
filesystem-and-grep equivalents — they are faster, less token-expensive, and
return current state rather than what's checked into the repo.

This pattern is added to the project's CLAUDE.md (or referenced from it) by the
`/boost-install` skill. Worker agents should consult it whenever CLAUDE.md
mentions Boost is installed.

---

## Tools provided

All Boost tools follow the naming convention `mcp__laravel-boost__<tool>`:

| Tool | Use it for | Prefer over |
|------|-----------|-------------|
| `application-info` | Stack snapshot — Laravel version, PHP version, env | reading composer.json + .env |
| `database-schema` | Current DB schema (tables, columns, types) | reading migration files (which only show migration order, not current state) |
| `database-query` | Run a read-only SELECT against the project's DB | hand-writing Tinker for "what's in this table" |
| `database-connections` | List configured DB connections | grepping `config/database.php` |
| `tinker` | Execute PHP / Eloquent in the Laravel context | scaffolding throwaway artisan commands |
| `list-routes` | Current route table with names, middleware, controllers | `php artisan route:list` + parsing |
| `list-artisan-commands` | Available artisan commands (incl. custom) | reading `app/Console/Commands/` directory |
| `get-config` | Resolved config value at a given dotted key | reading config files (which don't reflect env-var overrides) |
| `list-available-config-keys` | All addressable config keys | guessing |
| `list-available-env-vars` | Env vars the app reads | grepping for `env(` |
| `read-log-entries` | Recent log lines from `storage/logs/` | tailing files |
| `last-error` | Most recent exception with stack trace | hunting through logs |
| `browser-logs` | Browser console logs (if a browser session is hooked up) | n/a |
| `search-docs` | Semantic search of Laravel docs (and ecosystem packages) | guessing API surface from training data |
| `get-absolute-url` | Resolve a named route or relative path to a full URL | hand-building URLs |

## When to use which

**Schema-aware code generation**: before writing a model or migration, call
`database-schema` to see what already exists. Don't infer from migration filenames
or model `$casts` arrays — those drift from reality.

**Route inspection**: before scaffolding a controller, call `list-routes` to confirm
the route doesn't already exist and to see the project's actual middleware/naming
convention.

**Data exploration**: when the user asks "are there any users with X?" or "what's
in the settings table?" — `database-query` (read-only) or `tinker` (full power)
beats writing a one-shot artisan command.

**Config / env discovery**: never guess what's in `.env` from `.env.example`.
`list-available-env-vars` + `get-config` give the real values the app reads.

**Library / API research**: `search-docs` is semantic and version-aware. Use it
before any "I think Laravel does X" claim. Especially valuable for ecosystem
packages (livewire, filament, nova, sanctum, telescope, horizon, cashier, etc.).

**Error debugging**: when something fails, `last-error` is often a one-call
shortcut to the root cause vs. reading logs by hand.

## When NOT to use Boost

- **Writing files**: Boost is read-mostly. File creation/edits still go through
  Write/Edit tools.
- **Migrations**: `database-schema` reads current state, but creating a migration
  is still a Write operation.
- **Anything outside the Laravel runtime**: frontend code, infra, build configs —
  Boost only knows about the Laravel app itself.
- **Tests**: don't use `database-query` against the test database — use `tinker`
  with the appropriate env if you really need to inspect state during test runs.

## Safety notes

- `database-query` is read-only by design (raw SQL is checked for write
  statements). Use `tinker` if you need to mutate state — and only after
  confirming the env (NEVER in production unless explicitly authorized).
- `tinker` runs arbitrary PHP. Treat it like a REPL — don't paste code that
  could have side effects beyond what the user asked for.
- `last-error` and `read-log-entries` may surface user data. Don't paste raw
  results into commits, issues, or shared chats without scrubbing.

## See also

- Laravel Boost on GitHub: https://github.com/laravel/boost
- This addon's `/boost-install` skill — handles the install + MCP registration.
