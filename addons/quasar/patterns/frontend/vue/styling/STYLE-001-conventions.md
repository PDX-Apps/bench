---
mode: append
---

## Quasar theming (this project uses quasar)

Theme via the brand colors in `quasar.config` / `quasar.variables.scss` (`$primary`, `$secondary`, `$accent`, …) and the color prop + `text-*`/`bg-*` helper classes (`text-primary`, `bg-grey-2`). Don’t hard-code hex.

- Dark mode: `$q.dark.set(true|"auto")`; components adapt automatically.
- Spacing via Quasar spacing classes (`q-pa-md`, `q-mt-sm`); avoid ad-hoc CSS for what classes cover.
