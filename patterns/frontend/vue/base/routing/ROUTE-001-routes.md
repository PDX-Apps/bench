# Routing — route definitions

Vue Router 4 route records: lazy-loaded pages, layout nesting, typed `meta`, and navigation guards.

## Shape — `RouteRecordRaw[]` with lazy pages

```ts
// router/routes.ts
import type { RouteRecordRaw } from 'vue-router'

export const routes: RouteRecordRaw[] = [
  {
    path: '/',
    component: () => import('@/layouts/AppLayout.vue'), // layout as a parent route
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'home', component: () => import('@/pages/HomePage.vue') },
      {
        path: 'users',
        name: 'users',
        component: () => import('@/pages/users/UsersPage.vue'),
      },
      {
        path: 'users/:id',
        name: 'user-detail',
        component: () => import('@/pages/users/UserDetailPage.vue'),
        props: true, // route params → page props
      },
    ],
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('@/pages/auth/LoginPage.vue'),
    meta: { layout: 'guest' },
  },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/pages/NotFoundPage.vue') },
]
```

```ts
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import { routes } from './routes'

export const router = createRouter({ history: createWebHistory(), routes })
```

## Typed meta + auth guard

```ts
// router/meta.ts — augment RouteMeta so meta is typed everywhere
import 'vue-router'
declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    layout?: 'app' | 'guest'
  }
}
```

```ts
router.beforeEach((to) => {
  const { isAuthenticated } = useSessionStore()
  if (to.meta.requiresAuth && !isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})
```

## Conventions

- **Lazy-load every page** with `() => import(...)` for route-level code splitting.
- **`name` on each route** + named navigation (`router.push({ name: 'user-detail', params: { id } })`) — never hard-code path strings in components.
- **`props: true`** to pass route params as props (testable pages, no `useRoute()` coupling).
- **Layouts as parent routes** with `<router-view>` — the common, framework-native approach. (A `meta.layout` + dynamic-layout component is an alternative; match the project.)
- **Type `RouteMeta`** via module augmentation so guards and `to.meta` are type-checked.
- If the project uses **file-based routing** (`unplugin-vue-router` / Nuxt), match that instead of a manual array.

## Don't

- Don't import page components eagerly (kills code-splitting).
- Don't scatter literal path strings — use route `name`s.
- Don't put auth logic in components — use a `beforeEach` guard + `meta`.
