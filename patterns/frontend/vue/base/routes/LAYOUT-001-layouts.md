# LAYOUT-001-layouts

## Pattern

Layouts wrap route content with shared chrome (header, navigation, sidebar, footer). They live in `src/layouts/` (project-wide convention) or `src/modules/{Name}/layouts/` (per-module). Discover the project's convention from existing layouts.

## Typical Layout Types

| Layout | Used For |
|--------|----------|
| `AppLayout` | Authenticated app routes (default for new features) |
| `GuestLayout` | Auth pages (login, signup, password reset) |
| `LandingLayout` | Public marketing pages |

## Structure (compositional layout)

```vue
<script lang="ts" setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useSessionStore } from 'src/stores/sessionStore';
import { useBreadcrumbs } from 'src/composables/useBreadcrumbs';
import AppHeader from '../components/AppHeader.vue';
import AppSidebar from '../components/AppSidebar.vue';

const route = useRoute();
const session = useSessionStore();
const { breadcrumbs } = useBreadcrumbs();

const pageTitle = computed(() => (route.meta.title as string) ?? '');
</script>

<template>
  <div class="app-layout">
    <AppHeader :title="pageTitle" :breadcrumbs="breadcrumbs" />
    <AppSidebar :user="session.getUser" />

    <main class="app-page-container">
      <router-view />
    </main>
  </div>
</template>
```

If the project uses a UI library that provides a layout primitive (Quasar's `<q-layout>`, Vuetify's `<v-app>`, etc.), substitute it. Discover from existing layouts.

## Structure (delegating layout — common pattern)

Layouts can delegate to a more specific implementation, allowing variants (e.g., mobile-specific):

```vue
<script lang="ts" setup>
import WebAppLayout from './WebAppLayout.vue';
</script>

<template>
  <WebAppLayout />
</template>
```

## Usage in Routes

If the project uses layout routes, layouts are referenced as the parent route's component, with the actual page nested as a child:

```typescript
const routes: RouteRecordRaw[] = [
  {
    path: '/bills',
    component: () => import('src/layouts/AppLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: BillRoutes.LIST,
        component: () => import('../pages/BillsPage.vue'),
      },
    ],
  },
];
```

The `<router-view />` inside the layout renders the matched child page.

If the project doesn't use layout routes (each page imports its own layout), follow that convention.

## Conventions

- Suffix: `*Layout.vue` (`AppLayout.vue`, `GuestLayout.vue`)
- Layouts contain only chrome — they don't fetch domain data
- Root container appropriate to the project's UI library (plain `<div>`, `<q-layout>`, `<v-app>`)
- Render content via `<router-view />` (always a single one)
- Pull session/auth state via the project's session store (if it has one)
- Pull breadcrumbs via the project's breadcrumb composable (if it has one)
- Page title from `route.meta.title`

## Breadcrumb Integration

Routes declare breadcrumb metadata; layouts render them via the composable:

```typescript
// In routes.ts
meta: {
  breadcrumb: { label: 'bill.breadcrumb.list', icon: 'home' },
}
```

```typescript
// In layout
const { breadcrumbs } = useBreadcrumbs();
// breadcrumbs is computed list of { label, to, icon }
```

For dynamic labels (e.g., `/bills/:id` showing the bill name), use a function:

```typescript
meta: {
  breadcrumb: { label: (_route, ctx) => (ctx?.name as string) ?? 'Details' },
}
```

The Page provides context to the breadcrumb composable via `provideBreadcrumbContext()` (project-specific).

## Key Points

- Suffix: `*Layout.vue`, lives in `src/layouts/` or per-module `layouts/`
- One `<router-view />` per layout
- Don't fetch domain data in layouts — that's the Page's job
- Root container matches the project's UI library convention
- Wire breadcrumbs from route meta via the project's breadcrumb composable (if any)
- Reference in route definitions as the parent route's component (if the project uses layout routes)
