---
concern: layout
title: Project layout
order: 5
detect: ls -d Modules 2>/dev/null >/dev/null && echo modules || (ls -d app/Domain 2>/dev/null >/dev/null && echo ddd || echo flat)
questions:
  - id: layout
    ask: "How is the backend code organized?"
    options: [flat, modules, ddd, monorepo]
    default: detect
  - id: root
    ask: "If a monorepo / nested app, where does Laravel live? (e.g. apps/api, or '.' for repo root)"
    default: "."
  - id: namespace
    ask: "Per-module namespace pattern, if modular (e.g. Modules\\{Name}, App\\{Name}) — skip for flat."
    default: "App"
affects:
  - laravel/http/controllers/CONTROLLER-001-resource.md
  - laravel/models/MODEL-001-structure.md
  - laravel/database/migrations/MIGRATION-001-structure.md
output: overrides
---

## Apply

Layout drives **where generated code lands**. Write `.bench/patterns/...` overrides (mode `append`) to the representative patterns so every artifact follows the project's layout:

- For `modules`/`ddd`/`monorepo`: append a `## This project's layout` note to **CONTROLLER-001, MODEL-001, MIGRATION-001** (and others as needed) giving the real paths + namespace (`{root}` + `{namespace}` + `{layout}`) — e.g. "controllers live at `Modules/{Module}/Http/Controllers/`, namespace `Modules\{Module}\Http\Controllers`".
- For `flat`: the base `app/` paths are already correct — note it, no override needed.

Because layout cross-cuts, prefer a concise note on the representative patterns rather than overriding every file.
