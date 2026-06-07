# ROUTE-001 — Routes (Blade-rendered project)

This project renders UI with **Blade**. Routing is **not** owned by Vue Router here.

URL → view mapping is a Laravel route returning a Blade view — use your Laravel routes file
via `/blade`. For a full Vue SPA booted from a Blade shell, see `BLADE-005-spa-handoff`
(one catch-all route).

Do not scaffold a `router/index.ts` or Vue Router entry.
