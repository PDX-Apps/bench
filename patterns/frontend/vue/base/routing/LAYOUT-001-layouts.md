# Routing — layouts

A **layout** is the persistent shell around pages — header, nav, footer, slots — that stays mounted across route changes while the page content swaps. This is how you build one.

## The core idea

A layout is just a component with a `<router-view />` (or a `<slot />`) where page content renders. Wire it as a **parent route** so it stays mounted while children change (see [ROUTE-001](./ROUTE-001-routes.md)).

```vue
<!-- layouts/AppLayout.vue -->
<script setup lang="ts">
import { RouterView, RouterLink } from 'vue-router'
</script>

<template>
  <div class="app-layout">
    <header class="app-layout__header">
      <RouterLink :to="{ name: 'home' }">Acme</RouterLink>
      <nav>
        <RouterLink :to="{ name: 'users' }">Users</RouterLink>
      </nav>
      <slot name="header-actions" />
    </header>

    <main class="app-layout__main">
      <!-- child route renders here; stays within the persistent shell -->
      <RouterView />
    </main>

    <footer class="app-layout__footer">© Acme</footer>
  </div>
</template>

<style scoped>
.app-layout { display: grid; grid-template-rows: auto 1fr auto; min-height: 100dvh; }
.app-layout__main { padding: var(--space-4, 1rem); }
</style>
```

## Multiple layouts

Most apps need a couple: an authenticated **app** shell and a minimal **guest/auth** shell. Two ways:

1. **Layout-as-parent-route** (shown above) — nest pages under the layout route. Simple, framework-native, layout state persists. *Base default.*
2. **Dynamic layout** — a single `App.vue` picks a layout component from `route.meta.layout`. Use when many top-level routes share layouts without deep nesting:

```vue
<!-- App.vue -->
<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from '@/layouts/AppLayout.vue'
import GuestLayout from '@/layouts/GuestLayout.vue'

const route = useRoute()
const layout = computed(() => (route.meta.layout === 'guest' ? GuestLayout : AppLayout))
</script>

<template>
  <component :is="layout"><RouterView /></component>
</template>
```

## Conventions

- **`{Name}Layout.vue`** in `layouts/`. One responsibility: structure + persistent chrome, no page logic.
- **`<RouterView />`** (parent-route style) or **`<slot />`** (dynamic style) marks where the page goes.
- **Named slots** (`header-actions`, `breadcrumbs`) let pages inject into the shell.
- Layout = structure only. Theme/spacing come from your styling system ([STYLE-001](../styling/STYLE-001-conventions.md)); if the project uses a UI library, its layout primitives (e.g. a drawer/app-bar) replace the hand-rolled shell — match them.

## Don't

- Don't put data fetching or business logic in a layout — it's chrome.
- Don't re-mount the layout on every navigation (that's what parent-route nesting avoids).

## See also

- [ROUTE-001](./ROUTE-001-routes.md) · [PAGE-001](./PAGE-001-pages.md) · [STYLE-001](../styling/STYLE-001-conventions.md)
