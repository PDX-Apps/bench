---
description: Reference for using Laravel Boost MCP tools effectively (search-docs, tinker, database-query, browser-logs, etc.). Use when an agent needs to interact with the Laravel ecosystem.
disable-model-invocation: false
---

You are using a Laravel project that has the **Laravel Boost MCP server** installed. Use its tools instead of guessing or improvising.

---

## Documentation Search (CRITICALLY IMPORTANT)

**Always use `search-docs` BEFORE implementing Laravel features.** Returns version-specific docs for installed packages (Laravel, Inertia, Livewire, Filament, Tailwind, Pest, Nova, etc.).

### Query rules
- Use **multiple, broad, simple, topic-based** queries: `['rate limiting', 'routing rate limiting', 'routing']`
- Do NOT add package names to queries — package info is already shared. ✅ `test resource table` ❌ `filament 4 test resource table`
- Pass an array of packages to filter if you know which packages you need docs for

### Search syntax
| Syntax | Behavior | Example |
|--------|----------|---------|
| Simple words | Auto-stemming | `authentication` finds 'authenticate', 'auth' |
| Multiple words | AND logic | `rate limit` finds both "rate" AND "limit" |
| Quoted phrases | Exact match | `"infinite scroll"` finds exact phrase |
| Mixed | Combined | `middleware "rate limit"` |
| Array | OR logic across queries | `["authentication", "middleware"]` |

---

## Other Boost Tools

### Artisan
- **Use `list-artisan-commands`** to check available parameters before calling Artisan commands
- Combine with `--no-interaction` so commands don't hang waiting for input
- Always use `--module={Name}` for module-scoped generation

### URLs
- **Use `get-absolute-url`** for correct scheme/domain/IP/port. Don't hardcode `http://localhost:8000`.

### Debugging
- **`tinker`** — execute arbitrary PHP, debug, query Eloquent models directly
- **`database-query`** — read-only DB queries (faster than tinker for simple lookups)
- **`browser-logs`** — read browser errors/exceptions (only recent logs are useful)
- **`last-error`** — read the last application error
- **`read-log-entries`** — read application log entries

### Schema/Config introspection
- **`database-schema`** — full schema info without running migrations
- **`database-connections`** — list configured connections
- **`get-config`** — read a config value (prefer this over reading config files)
- **`list-available-config-keys`** — discover what's configurable
- **`list-available-env-vars`** — discover what env vars are documented
- **`list-routes`** — list all registered routes (faster than reading route files)
- **`application-info`** — Laravel version, PHP version, package versions

---

## Anti-Patterns

- ❌ Don't run `php artisan mcp:start` — it hangs waiting for JSON-RPC requests
- ❌ Don't grep route files manually — use `list-routes`
- ❌ Don't `cat` the config — use `get-config`
- ❌ Don't guess artisan flags — use `list-artisan-commands`
- ❌ Don't add package names to `search-docs` queries

---

## When local HTTPS fails

Some MCP clients use Node with its own certificate store. If local `https://` connections fail in dev, switch to `http://` for local development only.
