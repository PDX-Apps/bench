# ROUTE-001 — Routes (Blade-rendered project)

This project renders UI with **Blade**. Routing is **not** owned by Vue Router here.

URL → view mapping is a Laravel route returning a Blade view — use your Laravel routes file
via the Blade track (`/blade`), not a Vue router. A full Vue SPA booted from a Blade shell
uses a single catch-all route instead.

Do not scaffold a `router/index.ts` or Vue Router entry.
