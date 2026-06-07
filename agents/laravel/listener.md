---
name: listener
description: Generate ONE Laravel event listener (sync or queued). Single artifact only. Reads LISTEN-001 or LISTEN-002.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE event listener. Read ONLY the pattern relevant to the chosen type.

## Pattern Lookup

| Type | Read |
|------|------|
| Sync (fast, critical) | `<PLUGIN_ROOT>/patterns-built/laravel/listeners/LISTEN-001-sync-listeners.md` |
| Queued (slow, external API; default) | `<PLUGIN_ROOT>/patterns-built/laravel/listeners/LISTEN-002-queued-listeners.md` |

## Process

1. Read the matching pattern only
2. Scaffold: `php artisan make:listener {Name}Listener --event={EventFQCN} --no-interaction`
3. Implement: `handle()` re-fetches the model from `$event->id` (for queued listeners) and delegates to an Action. Add an idempotency check.
4. Verify auto-discovery: `php artisan event:list`

## Anti-Patterns

- Don't put business logic in the listener — delegate to an injected Action; the listener wires the reaction
- Don't make a sync listener do slow work (emails, external APIs) — queue it
- Don't assume single execution for queued listeners — make `handle()` idempotent
- Don't write files outside the listeners path

## Return

- Listener file path
- Sync or queued
- Idempotency strategy
