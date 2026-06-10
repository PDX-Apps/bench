# QUERY-001 — Page data (Blade-rendered project)

This project renders UI with **Blade**. Page data is server-provided (controller → Blade
view); islands fetch directly or receive props. There is no SPA query layer. A full SPA
booted from a Blade shell brings its own data layer.

Do not scaffold a TanStack Query hook or query-client registration.
