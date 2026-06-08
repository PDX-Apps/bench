---
mode: append
---

## UnoCSS (this project uses unocss)

Style with **atomic utility classes** in `class`/`className`, generated on-demand by UnoCSS. Don't emit scoped/module CSS except for dynamic values.

- Utilities resolve from the project's `uno.config.ts` presets (`presetWind`/`presetUno`, icons, attributify, shortcuts). Match the presets the project enabled.
- **Shortcuts** (`shortcuts: { btn: 'px-4 py-2 rounded' }`) for repeated clusters — prefer these over inline repetition.
- **Theme tokens** come from the config `theme` (e.g. `theme.colors.primary`) → `bg-primary`, `text-primary`.
- Dark mode via the `dark:` variant + a `.dark` class (or the configured dark selector).
- If **attributify** is enabled, attributes (`<button bg="primary" p="x-4 y-2">`) are also valid — match what existing components use.
