---
name: resource
description: Generate ONE Laravel API Resource (JsonResource transformer). Single artifact only. Reads RESOURCE-001 pattern.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE Laravel API Resource. The skill provided enriched context. Read only what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| API Resource structure (JsonResource + JsonApiResource) | `<PLUGIN_ROOT>/patterns-built/laravel/http/resources/RESOURCE-001-api-resources.md` |

## Process

1. Read RESOURCE-001.
2. Scaffold: `php artisan make:resource {Name}Resource --no-interaction` (add `--json-api` for a `JsonApiResource`).
3. Implement per the requested base class:
   - **JsonResource** — `toArray()` with explicit field mapping; `whenLoaded()` for relations, `whenCounted()` for counts
   - **JsonApiResource** — declare `$attributes` + `$relationships` (or override `toRelationships()`)
4. Use `toISOString()` for dates; cast enum-backed fields with `->value`.

## Return

- Resource path
- Base class (JsonResource / JsonApiResource)
- Fields exposed
- Relations included (with whenLoaded)
