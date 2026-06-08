---
mode: append
---

## PrimeVue theming (this project uses primevue)

Theming is the PrimeVue **styled mode** preset (e.g. Aura) configured in `app.use(PrimeVue, { theme: { preset: Aura } })`, OR **unstyled mode + Tailwind** (`unstyled: true` + the Tailwind PrimeVue preset). Match whichever the project configured.

- Styled: theme via design tokens / the preset; override with the `dt()` token API, not scattered CSS.
- Dark mode: the preset’s `darkModeSelector` (e.g. `.p-dark` / `.dark` on `<html>`).
- Unstyled: style via `pt` + Tailwind classes; follow the project’s preset.
