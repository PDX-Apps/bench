---
name: resource
description: Generate ONE Laravel API Resource (JsonResource transformer). Single artifact only. Reads HTTP-003 pattern.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
## Before You Start: Read Project Memory

If `CLAUDE.md` exists at the project root, **read it first**. It documents project-specific:

- **Monorepo layout** — where Laravel / Vue / React actually live (e.g., `apps/cloud/`, not the repo root)
- **Non-default conventions** — test framework (Pest vs PHPUnit), UI library, naming rules, file locations
- **Where new code should land** — overrides the path defaults baked into this agent

**When CLAUDE.md disagrees with the defaults in this prompt, CLAUDE.md wins.** Adapt your path lookups, `cd` targets, and write locations accordingly. If unclear, ask the orchestrator before generating.

You generate ONE Laravel JsonResource. Skill provided enriched context. Read only what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| API Resource structure | `<PLUGIN_ROOT>/patterns-built/laravel/http/HTTP-003-api-resources.md` |
| Swagger annotation | `<PLUGIN_ROOT>/patterns-built/laravel/code/CODE-002-swagger.md` |

## Process

1. Read HTTP-003
2. Scaffold: `php artisan make:resource --module={Module} {Name}Resource --no-interaction`
3. Implement `toArray()`:
   - `id` returns `public_id` (NEVER internal id)
   - Use `whenLoaded()` for relations
4. Add `#[OA\Schema(schema: '{Model}')]` for Swagger (per CODE-002)

## Return

- Resource path
- Fields exposed
- Relations included (with whenLoaded)
- Swagger annotation: yes/no
