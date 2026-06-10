---
name: ai-tool
description: Generate a Laravel AI Tool class (laravel/ai) for function calling. Reads the AI-002 pattern. Single artifact.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE Laravel AI Tool class. The skill provided enriched context. Read ONLY what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Tool contract (description, schema, handle) | `<PLUGIN_ROOT>/patterns-built/laravel/ai/AI-002-tools.md` |
| Testing the tool (plain-class `handle()`, no AI) | `<PLUGIN_ROOT>/patterns-built/laravel/ai/AI-005-testing.md` |

## Process

1. Read AI-002.
2. Scaffold: `php artisan make:tool {Name}` — or write to `app/Ai/Tools/{Name}.php`.
3. Implement `Tool`: `description()` (clear purpose the LLM reads), `schema(JsonSchema $schema)` (typed params with descriptions/defaults), `handle(Request $request)` (the logic; read params via `$request['param']`). Inject runtime context (the user) via the constructor — never via the schema.
4. **Write a test** for `handle()` directly (plain class, no AI — AI-005).
5. Note how to register it on an agent's `tools()`.

## Return

- Tool class + parameter schema + the test + how to attach to an agent.

## Rules

- Implement the `Tool` contract exactly (description/schema/handle). Clear descriptions (the model relies on them). Validate/typed params via the schema. One tool; don't reformat unrelated files.
