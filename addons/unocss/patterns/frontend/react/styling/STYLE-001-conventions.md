---
mode: append
---

## UnoCSS (this project uses unocss)

UnoCSS is an **on-demand atomic CSS engine** — utilities are generated only for the classes you actually use. Style with utility classes in `className`; treat `uno.config.ts` as the single source of tokens, shortcuts, and custom utilities. Don't write CSS-module blocks except for genuinely dynamic values.

### `uno.config.ts` — the control center

```ts
import {
  defineConfig,
  presetWind3,             // Tailwind/Windi-compatible utilities (core). presetWind4 = Tailwind v4-aligned.
  presetAttributify,       // attributify mode
  presetIcons,             // pure-CSS icons via Iconify
  transformerDirectives,   // enables @apply / theme() in CSS
  transformerVariantGroup, // enables hover:(...) group syntax
} from 'unocss'

export default defineConfig({
  presets: [presetWind3(), presetAttributify(), presetIcons({ scale: 1.2 })],
  transformers: [transformerDirectives(), transformerVariantGroup()],
  theme: { colors: { primary: 'hsl(221 83% 53%)', surface: 'hsl(0 0% 100%)' } },
  shortcuts: [
    { btn: 'px-4 py-2 rounded font-medium disabled:op-50' },
    [/^btn-(\w+)$/, ([, c]) => `btn bg-${c}-500 text-white hover:bg-${c}-600`],
  ],
})
```

> `presetUno`/`presetWind` are the **legacy names** for `presetWind3` — match whatever the project imports. Specifying `presets` overrides the defaults, so every preset you need must be listed.

### Utilities, variants, groups

- Utilities mirror Tailwind: `p-4 flex gap-2 text-sm bg-primary rounded`.
- Variants stack: `hover:bg-primary/90 md:flex dark:bg-surface focus-visible:ring`.
- **Variant groups** (via `transformerVariantGroup`) collapse repetition: `hover:(bg-gray-100 text-primary) md:(grid grid-cols-2 gap-4)`.
- **Dark mode**: the `dark:` variant; the default selector is the `.dark` class on a root element (configurable).

### Theme tokens

`theme.colors.primary` → `bg-primary` / `text-primary` / `border-primary`. Reference tokens, never raw hex in markup. With `transformerDirectives`, tokens are also reachable in CSS via `theme('colors.primary')`.

### Shortcuts vs rules

- **Shortcuts** alias utility clusters — static (`{ btn: '...' }`) or **dynamic** (`[/^btn-(\w+)$/, ([, c]) => '...']`). Prefer them over repeating clusters in markup and over `@apply`.
- **Rules** add brand-new utilities UnoCSS doesn't ship — static (`['custom', { color: 'red' }]`) or dynamic with a regex handler returning a CSS object (`[/^m-(\d+)$/, ([, d]) => ({ margin: `${d / 4}rem` })]`).

### Icons (presetIcons)

Pure-CSS icons from any Iconify set — no components. Class = `i-{collection}-{name}`:

```tsx
<div className="i-mdi-home text-2xl" />
<button className="i-carbon-search hover:text-primary" />
```

Install the sets you use (`npm i -D @iconify-json/mdi @iconify-json/carbon`); size/color via normal utilities.

### Attributify mode (presetAttributify)

Utilities can move into attributes — useful for long class lists; works alongside `className`:

```tsx
<button bg="blue-500 hover:blue-600" text="sm white" p="x-4 y-2" rounded>Save</button>
```

### CSS directives (transformerDirectives)

In CSS, `@apply` (or `--at-apply` for vanilla-CSS compat) and `theme()` resolve UnoCSS tokens — reserve for the rare case a shortcut can't cover:

```css
.card { @apply p-4 rounded bg-surface shadow; }
.title { color: theme('colors.primary'); }
```

### Conventions

- `uno.config.ts` owns tokens, shortcuts, and custom utilities — change design there, not with scattered CSS.
- Utilities in markup; repeated clusters → **shortcuts**; missing primitives → **rules**.
- Reference theme tokens (`bg-primary`), never raw hex; icons via `i-{set}-{name}`.
- Classes not present in source (built dynamically) won't generate — list them in `safelist`.
- Conditional classes: merge with `cn()`/clsx — never string-concat.

### Don't

- Don't write module CSS for what utilities/shortcuts cover.
- Don't repeat long utility clusters across components — extract a shortcut.
- Don't `@apply` everything into CSS — that rebuilds the soup utilities avoid.
- Don't use a preset's utilities (icons, typography, attributify) without enabling that preset — they silently won't generate.
