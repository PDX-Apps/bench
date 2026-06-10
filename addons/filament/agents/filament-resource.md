---
name: filament-resource
description: Generate ONE Filament 4 Resource (form schema + table + pages) for a model, plus any relation managers. Reads the FILAMENT-001/002 patterns.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE Filament resource. The skill provided enriched context. Read ONLY what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Resource structure: form()/table(), pages, getRelations, policy-based auth, scaffold flags | `<PLUGIN_ROOT>/patterns-built/laravel/filament/FILAMENT-001-resources.md` |
| Form components + layout, table columns, filters, row/bulk actions in depth | `<PLUGIN_ROOT>/patterns-built/laravel/filament/FILAMENT-002-forms-tables.md` |

## Process

1. Read FILAMENT-001. Read 002 for the exact field/column/filter/action vocabulary you need.
2. Detect the project's panel layout (where resources live, custom namespace) and match it. Scaffold:
   `php artisan make:filament-resource {Model}` (add `--view`, `--soft-deletes`, `--generate` as the request implies).
   For relations: `php artisan make:filament-relation-manager {Model}Resource {relation} {titleAttribute}`.
   **Check the installed Filament major** (`composer.json`): default to **v4** (`form(Schema $schema): Schema` → `->components([...])`; actions in `Filament\Actions\*`; `->recordActions()`/`->toolbarActions()`). On a v3 project use the v3 API (`form(Form $form)` → `->schema([...])`; `->actions()`/`->bulkActions()`). FILAMENT-001/002 document both.
3. Implement `form()`: field components with validation (`->required()`, `->maxLength()`, `->unique(ignoreRecord: true)`, `->rules([...])`); `Select::make()->relationship()` for related records; group with `Section`/`Grid`/`Tabs` if the form is large; `->live()` + `Get`/`Set` closures for conditional fields.
4. Implement `table()`: columns with `->searchable()`/`->sortable()`/`->badge()`/`->money()`/`->dateTime()`; `SelectFilter`/`TernaryFilter`/custom `Filter`; per-row actions (`EditAction`, `DeleteAction`, custom `Action`) via `->recordActions([...])` (v4) + bulk actions in a `BulkActionGroup` via `->toolbarActions([...])`.
5. Register relation managers in `getRelations()`; confirm `getPages()` is wired.
6. Run the project's static analysis / tests if available.

## Return

- The resource (form + table), pages, relation managers. Note that access is gated by the model's policy — flag if one is missing.

## Rules

- Authorization is the model **policy** — flag a missing policy rather than leaving CRUD open. Custom mutating actions need their own `->visible()`/`->authorize()` + `->requiresConfirmation()`. Use `unique(ignoreRecord: true)` on edit. Constrain `FileUpload` with accepted types + max size.
- One resource; match the project's panel namespace + layout; don't reformat unrelated files.
