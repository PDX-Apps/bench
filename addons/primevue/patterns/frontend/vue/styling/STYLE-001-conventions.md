---
mode: append
---

## PrimeVue theming (this project uses primevue)

PrimeVue v4 theming is **design-token based**. Pick a preset, configure it once, and customize through tokens — not by overriding `.p-*` CSS.

### Styled mode (the default)

Configure a preset (`Aura`, `Lara`, or `Nora`) from `@primeuix/themes`:

```ts
import PrimeVue from "primevue/config"
import Aura from "@primeuix/themes/aura"

app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      darkModeSelector: ".dark",   // class on <html> that flips to dark tokens (or "system")
      cssLayer: false,             // set to a layer name to control Tailwind/PrimeVue precedence
    },
  },
})
```

### Customize with `definePreset` (design tokens)

Tokens cascade **primitive → semantic → component**. Override semantic tokens (the brand layer) rather than hex in markup:

```ts
import { definePreset } from "@primeuix/themes"
import Aura from "@primeuix/themes/aura"

const AppTheme = definePreset(Aura, {
  semantic: {
    primary: { 500: "{blue.500}", 600: "{blue.600}" },   // reference primitive tokens
  },
})
// app.use(PrimeVue, { theme: { preset: AppTheme } })
```

- **Runtime token access**: the `dt()` function (and the per-component `dt` prop) reads/sets tokens without writing CSS.
- **Dark mode**: toggle the class named in `darkModeSelector` on `<html>`; semantic tokens resolve per scheme automatically.

### Unstyled mode + Tailwind (alternative)

When the project opted out of the built-in theme (`unstyled: true`), components ship no styles — style them via `pt` (PassThrough) presets and Tailwind, typically with the `tailwindcss-primeui` plugin. Follow the project's chosen preset; don't mix the two modes.

### Don't

- Don't override `.p-*` CSS selectors — use semantic tokens / `definePreset` / `dt` / `pt`.
- Don't hard-code hex in markup — reference semantic tokens so theming stays centralized.
- Don't import presets from `@primevue/themes` (the v4 package is **`@primeuix/themes`**).
