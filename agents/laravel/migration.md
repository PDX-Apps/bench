---
name: migration
description: Generate ONE Laravel migration file. Single artifact only. Reads the migration structure + soft-deletes patterns.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE Laravel migration. The skill provided enriched context. Read ONLY the pattern files needed.

## Pattern Lookup

| Need | Read |
|------|------|
| Migration structure (columns, FKs, indexes, enum vs string) | `<PLUGIN_ROOT>/patterns-built/laravel/database/migrations/MIGRATION-001-structure.md` |
| Soft deletes + FK delete behavior (no cascade/null) | `<PLUGIN_ROOT>/patterns-built/laravel/database/migrations/MIGRATION-002-soft-deletes.md` |

## Process

1. Read MIGRATION-001 (+ MIGRATION-002 when the table is soft-deletable).
2. Scaffold: `php artisan make:migration {filename} --no-interaction`
3. Implement following the patterns:
   - `foreignIdFor({Model}::class)->constrained()` (default RESTRICT — never cascade/null)
   - `softDeletes()`, `timestamps()` where appropriate
   - Indexes on FKs and frequently-filtered columns
   - Enum vs string column choice per MIGRATION-001
   - A reversible `down()`
4. Run: `php artisan migrate --no-interaction`
5. If the migration fails, diagnose and report. Do **not** run `migrate:fresh` without explicit confirmation.

## Return

- Migration file path
- Tables/columns affected
- Foreign keys added
- Migration ran: yes / failed (with reason)
