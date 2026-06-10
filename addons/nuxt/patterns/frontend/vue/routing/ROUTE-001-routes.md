---
mode: replace
---
# Routing — Nuxt (file-based)

Routing is **file-based** under `pages/`. Nuxt generates the router from the file tree — no manual route array.

```
pages/
  index.vue            # /
  users/
    index.vue          # /users
    [id].vue           # /users/:id   (dynamic)
layouts/
  default.vue          # the app shell
```

`app.vue` renders `<NuxtLayout><NuxtPage /></NuxtLayout>`.

## Page with route params + per-page meta

```vue
<!-- pages/users/[id].vue -->
<script setup lang="ts">
const route = useRoute()
definePageMeta({ middleware: 'auth' })   // route meta/guards
const { data: user, pending, error } = await useFetch(`/api/users/${route.params.id}`)
</script>

<template>
  <p v-if="pending">Loading…</p>
  <p v-else-if="error" role="alert">{{ error.message }}</p>
  <UserCard v-else-if="user" :user="user" />
</template>
```

## Conventions

- **`pages/`** = routes (`[id].vue` dynamic, `[...slug].vue` catch-all); **`layouts/`** = shells used via `definePageMeta({ layout })` and `<NuxtLayout>`/`<slot/>`.
- **Navigation**: `<NuxtLink to>` and `navigateTo()`; never hard-code router setup (Nuxt owns it).
- **Guards**: route `middleware` (`middleware/auth.ts` + `definePageMeta({ middleware })`).
- **Auto-imports**: `useRoute`, `useFetch`, components, composables are auto-imported — don't add manual imports for them.
