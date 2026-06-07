---
name: boost-install
description: |
  Use this skill when the user wants to install Laravel Boost (laravel/boost)
  in a Laravel project — the MCP server that gives AI agents direct Laravel
  tooling like database-schema, tinker, list-routes, and search-docs. Triggers
  on "/boost-install", "install laravel boost", "set up boost mcp", "add the
  laravel mcp server", "give claude database access for this project".
  Walks through composer install + php artisan boost:install + verifies MCP
  registration, with user permission at each step.
---

# /boost-install

Installs Laravel Boost in a Laravel project and verifies its MCP server is
registered with Claude Code. Asks user permission before each step that
modifies the project, package list, or settings.

## Usage

```
/boost-install                          # interactive, default behavior
/boost-install --laravel-root=PATH      # explicit Laravel root (monorepos)
/boost-install --no-mcp                 # composer require + boost:install only,
                                        # skip the post-install MCP verification
/boost-install --no-claude-md           # don't append a Boost section to CLAUDE.md
```

## What this skill does

1. **Resolve the Laravel root**. Try in order:
   - `--laravel-root=PATH` if provided
   - Project root (if `composer.json` is there)
   - Read CLAUDE.md for a documented Laravel path (e.g., `apps/api/`)
   - Ask the user if ambiguous

2. **Check the current state** (read-only, no permission needed):
   - Is `laravel/boost` already in `composer.json`?
   - Is `boost.php` config / `.mcp.json` MCP entry already present?
   - If everything's already set up, report and exit early.

3. **Delegate to `boost-installer` agent** with the resolved context. The agent
   walks through each install step, asking permission via natural-language
   prompts before running anything that modifies the project.

4. **Report back** what was installed, what was skipped, and what the user
   should do next (typically: restart Claude Code so the MCP server connects).

## What this skill does NOT do

- Run installs without permission. Every `composer require`, `php artisan`, or
  settings-file edit gets confirmed first.
- Touch global Composer or system PHP — installation is scoped to the project's
  Laravel root.
- Force-enable Boost if the user declines individual steps.
- Modify production envs. Boost is a dev-only dependency.

## Delegation

```
Task(
  subagent_type: "boost-installer",
  description: "Install Laravel Boost in {laravel_root}",
  prompt: """
  Walk through installing Laravel Boost.

  - laravel_root: {resolved_path}
  - project_root: {cwd}
  - register_mcp: {true unless --no-mcp}
  - update_claude_md: {true unless --no-claude-md}

  Follow the workflow in your agent file. Ask user permission before each
  state-modifying step. Report the final state when done.
  """
)
```

## What happens after install

Once Boost is installed and the MCP server is registered:

- **Restart Claude Code** so the MCP server connects (one-time).
- The next worker agent invocation will have access to `mcp__laravel-boost__*`
  tools (database-schema, tinker, list-routes, search-docs, etc.).
- If `--no-claude-md` was NOT passed, the project's `CLAUDE.md` now mentions
  Boost so future agents prefer Boost tools over filesystem grepping.

See `patterns-built/laravel/boost-awareness.md` for full guidance on when to
use which Boost tool.
