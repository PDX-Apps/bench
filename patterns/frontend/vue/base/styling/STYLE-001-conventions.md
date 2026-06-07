# Styling & theming

Styling is the **most project-specific** decision in a frontend — there is no single right answer. The rule for generated code is therefore: **detect the project's styling system and match it.** This pattern defines the detection order and the zero-dependency default.

## Detect first — match what the project already does

Before styling a generated component, determine the project's approach (from `package.json` + a couple of existing components):

| Signal | System | Generate… |
|--------|--------|-----------|
| `tailwindcss` dep + `@tailwind`/`@import "tailwindcss"` | **Tailwind** | utility classes in `class="…"`; no `<style>` block (`bench-tailwind` addon sharpens this) |
| `unocss` dep | **UnoCSS** | atomic classes; presets per config (`bench-unocss`) |
| A UI library (`primevue`, `vuetify`, `quasar`, `naive-ui`, shadcn-vue components in `components/ui/`) | **UI library** | the library's components + its theming system (its `bench-*` addon) |
| `*.module.css` imports | **CSS Modules** | `<style module>` / `styles.x` |
| only `<style scoped>` in existing components | **Scoped CSS** | `<style scoped>` |

**Match the dominant signal.** A generated component must look like the team's other components.

## Greenfield default — `<style scoped>` + CSS custom properties

When there's nothing to detect, use the **zero-dependency** built-in: scoped CSS, with **CSS variables for theming** so the app can be themed without a framework.

```vue
<template>
  <button class="btn" :class="`btn--${variant}`"><slot /></button>
</template>

<script setup lang="ts">
defineProps<{ variant?: 'primary' | 'ghost' }>()
</script>

<style scoped>
.btn {
  padding: var(--space-2, 0.5rem) var(--space-4, 1rem);
  border-radius: var(--radius, 0.375rem);
  font: inherit;
  cursor: pointer;
}
.btn--primary { background: var(--color-primary, #2563eb); color: var(--color-on-primary, #fff); }
.btn--ghost { background: transparent; color: var(--color-primary, #2563eb); }
</style>
```

```css
/* assets/theme.css — design tokens as custom properties; the single theming surface */
:root {
  --color-primary: #2563eb;
  --color-on-primary: #fff;
  --space-1: 0.25rem; --space-2: 0.5rem; --space-3: 0.75rem; --space-4: 1rem;
  --radius: 0.375rem;
}
:root[data-theme='dark'] {
  --color-primary: #3b82f6;
}
```

## Conventions

- **Match, don't impose.** The base never forces Tailwind or a UI library; it adapts. Opinionated systems are addons (`bench-tailwind`, `bench-unocss`, `bench-primevue`, `bench-vuetify`, `bench-quasar`, `bench-shadcn-vue`).
- **Theme via CSS custom properties** (greenfield). One token file is the theming surface; dark mode = a `[data-theme]` / `prefers-color-scheme` override of the same vars. No hard-coded colors scattered in components.
- **Scoped by default** so styles don't leak; reach for `:global()` deliberately.
- **No inline `style="…"`** except for genuinely dynamic, computed values (a measured width, a transform). Static styling goes in classes.

## Don't

- Don't introduce a styling dependency (Tailwind, a UI lib) the project doesn't already use — recommend the matching addon instead.
- Don't hard-code colors/spacing — use tokens (CSS vars, or the project's Tailwind/theme config).
- Don't scatter inline styles for static rules.

## See also

- [COMPONENT-001](../components/COMPONENT-001-conventions.md) · addons: `bench-tailwind`, `bench-unocss`, `bench-primevue`, `bench-vuetify`, `bench-shadcn-vue`, `bench-quasar`
