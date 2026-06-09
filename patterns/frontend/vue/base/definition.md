# Vue Patterns

> The generic Vue 3 base. Conventions that are broadly settled across modern Vue apps — and **explicit deferral** on the things that aren't (styling, UI library, data layer, folder structure). Opinionated choices ship as **addons**.

## Philosophy — what the base commits to, and what it defers

Frontend has far fewer universal conventions than a backend framework. So this base is deliberately thin:

- **Prescribed** (settled in modern Vue): `<script setup>` + Composition API + TypeScript (strict), **Pinia** for state, **Vue Router**, **Vite**, **Vitest** for tests. Generate these the same way everywhere.
- **Deferred — detect and match the project** (no single right answer):
  - **Styling** — scoped CSS, Tailwind, UnoCSS, or a UI library's system. The base teaches component *structure*; the agent detects the project's styling from `package.json` + existing components and **matches it**. Greenfield default: `<style scoped>` + CSS custom properties (zero-dependency). See [styling/STYLE-001](./styling/STYLE-001-conventions.md).
  - **Component library** — none/headless in the base. PrimeVue, Vuetify, shadcn-vue, Quasar, etc. are **addons**.
  - **Data fetching** — the base ships **query composables via TanStack Query (Vue Query)**; [Pinia Colada](https://pinia-colada.esm.dev) is the Vue-native alternative (addon). No "service class" layer.
  - **Folder structure** — feature/domain folders are the modern lean for non-trivial apps, but the agent **matches the project's existing layout** (flat-by-type is fine for small apps).
  - **Meta-framework** — the base assumes a plain **Vite SPA**. Nuxt is a separate variant (addon).

> **Detect-and-match is the core move.** A generated component must look like the team's other components — same styling system, same folder, same data approach. When greenfield, use the zero-dependency default and say so.

## Patterns

| Area | Pattern |
|------|---------|
| Components | [components/COMPONENT-001-conventions.md](./components/COMPONENT-001-conventions.md) · [components/COMPONENT-002-forms.md](./components/COMPONENT-002-forms.md) |
| Composables | [composables/COMPOSABLE-001-conventions.md](./composables/COMPOSABLE-001-conventions.md) |
| State | [state/STORE-001-pinia-stores.md](./state/STORE-001-pinia-stores.md) |
| Data fetching | [data/QUERY-001-tanstack-query.md](./data/QUERY-001-tanstack-query.md) |
| Routing | [routing/ROUTE-001-routes.md](./routing/ROUTE-001-routes.md) · [routing/PAGE-001-pages.md](./routing/PAGE-001-pages.md) · [routing/LAYOUT-001-layouts.md](./routing/LAYOUT-001-layouts.md) |
| Types | [types/TYPE-001-types.md](./types/TYPE-001-types.md) |
| Validation | [validation/VALIDATOR-001-zod.md](./validation/VALIDATOR-001-zod.md) |
| Styling | [styling/STYLE-001-conventions.md](./styling/STYLE-001-conventions.md) |
| i18n (optional) | [i18n/I18N-001-vue-i18n.md](./i18n/I18N-001-vue-i18n.md) |
| Testing | [testing/TEST-001-vitest.md](./testing/TEST-001-vitest.md) |

## Tech stack (base)

- **Vue** 3.5+ (`<script setup>`, Composition API)
- **TypeScript** 5.x (strict)
- **Pinia** 3 (state) · **Vue Router** 4
- **Vite** (build/dev) · **Vitest** + `@vue/test-utils` (unit/component tests)
- **TanStack Query** (Vue Query) for server state · **Zod** for validation
- Styling: project's choice (base default `<style scoped>` + CSS variables)

## Addons (opt-in, per project)

Bench keeps the base generic and ships the popular opinionated choices as addons:

- **Styling:** `tailwind` · `unocss`
- **UI libraries:** `primevue` · `vuetify` · `shadcn-vue` · `quasar`
- **Data:** `pinia-colada` (Vue-native alternative to TanStack Query)
- **E2E testing:** `playwright` (the base ships Vitest unit/component tests)
- **Meta-framework:** `nuxt`

A project installs only the addons matching its stack; the agents then generate that flavour instead of the generic base.
