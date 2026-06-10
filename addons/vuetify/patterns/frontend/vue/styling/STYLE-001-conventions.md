---
mode: append
---

## Vuetify theming (this project uses vuetify)

Theme through Vuetify's **theme system** and utility classes, not ad-hoc CSS.

### Define themes

```ts
import { createVuetify } from "vuetify"

export default createVuetify({
  theme: {
    defaultTheme: "light",          // "light" | "dark" | "system"
    themes: {
      light: { colors: { primary: "#2563eb", secondary: "#7c3aed", surface: "#ffffff", error: "#dc2626" } },
      dark:  { colors: { primary: "#60a5fa", surface: "#121212" } },
    },
  },
})
```

Semantic color names (`primary`, `secondary`, `surface`, `background`, `error`, `info`, `success`, `warning`) plus their auto-generated `on-*` text colors. Reference them through component `color`/`bg-color` props and the `text-*` / `bg-*` helper classes (`text-primary`, `bg-surface`) — never raw hex in markup.

### Dark mode

Toggle the active theme through `useTheme()`:

```ts
import { useTheme } from "vuetify"
const theme = useTheme()
theme.global.name.value = theme.global.current.value.dark ? "light" : "dark"
```

Or set `defaultTheme: "system"` to follow the OS. Components and `text-*`/`bg-*` classes follow the active theme automatically.

### Global component defaults

Set app-wide component defaults once instead of repeating props — `createVuetify({ defaults: { VBtn: { variant: "flat" }, VTextField: { variant: "outlined", density: "comfortable" } } })`.

### Spacing, elevation, density

Use Vuetify utilities/props before writing CSS: spacing classes `pa-4`/`ma-2`/`px-6`, `elevation-2`, and the `density` prop (`default`/`comfortable`/`compact`) to tune component sizing.

### Don't

- Don't hard-code hex — define colors in the theme and use `text-*`/`bg-*` + `color` props.
- Don't repeat the same props everywhere — set them in `defaults`.
- Don't toggle dark mode by hand-swapping classes — use `useTheme()` / `defaultTheme: "system"`.
