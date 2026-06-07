---
mode: append
---

## Vuetify theming (this project uses bench-vuetify)

Theme via `createVuetify({ theme: { themes: { light, dark } } })` — semantic colors (`primary`, `surface`, `on-surface`). Reference them through component `color`/`bg-color` props and the `text-*`/`bg-*` helper classes, not raw hex.

- Dark mode: toggle `theme.global.name` (or `useTheme()`); both themes share token names.
- Spacing/elevation via Vuetify utility props/classes; avoid ad-hoc CSS for what props cover.
