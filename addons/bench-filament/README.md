# bench-filament

Build **admin panels** for Laravel with **Filament 3** — the TALL-stack (Tailwind, Alpine, Livewire, Laravel) resource builder. Declare a model's CRUD interface in PHP — a form schema and a table — and Filament renders the back-office UI.

## What it ships

- **`/filament-resource`** skill + **`filament-resource`** agent — scaffold (`php artisan make:filament-resource`) and implement a resource's form + table, pages, and relation managers.
- **Patterns:**
  - `FILAMENT-001-resources` — Resource conventions: `form()`/`table()`, pages, `getRelations()`, relation managers, policy-based authorization, scaffold flags.
  - `FILAMENT-002-forms-tables` — form components + layout, table columns, filters, and row/bulk actions in depth.

## Install

```bash
bench addon add /path/to/bench/addons/bench-filament
bench rebuild
```

Then:

```
/filament-resource Order — form: reference, status select, total; table: reference (searchable), status badge, total money; filter by status
/filament-resource Subscription with a relation manager for invoices
```

## Requires

- Filament 3 (`composer require filament/filament` + `php artisan filament:install --panels`).
- A panel set up, and ideally a **policy** on each managed model — Filament gates resource access through it.
