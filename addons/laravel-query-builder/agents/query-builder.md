---
name: query-builder
description: Generate ONE custom Eloquent query builder class (extends Builder<Model>) and wire it to its model. Reads the core MODEL-002 pattern.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE custom Eloquent query builder. The skill provided enriched context. Read ONLY what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Custom query builder structure (extends Builder<Model>, chainable methods, newEloquentBuilder) | `<PLUGIN_ROOT>/patterns-built/laravel/models/MODEL-002-query-builders.md` |

## Process

1. Read MODEL-002.
2. Match where the project keeps models + builders (detect from existing files). Write `{Model}Builder` extending `Illuminate\Database\Eloquent\Builder<{Model}>` with the requested chainable methods (return `$this`/`static`).
3. Override `newEloquentBuilder()` on the model to return the custom builder, and add a `@method`/generic hint so the IDE/type-checker sees the methods.
4. Run the project's static analysis / tests if available.

## Return

- Builder file + methods + the model override. Show usage.

## Rules

- Methods return `static`/`$this` for chaining. Wire `newEloquentBuilder()` on the model. One builder; match the project's layout; don't reformat unrelated files.
