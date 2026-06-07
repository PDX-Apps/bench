# Vue Component — conventions

How to write a single-file component in this project. Covers naming, anatomy, props/emits, `v-model`, slots. Styling is project-specific — see [STYLE-001](../styling/STYLE-001-conventions.md); the example here uses scoped CSS as the zero-dependency default.

## When

Any reusable piece of UI. Page-level route components are [PAGE-001](../routing/PAGE-001-pages.md); they follow the same anatomy.

## Naming + location

- **PascalCase** filenames and tags: `UserCard.vue`, `<UserCard />`. Multi-word always (avoids clashing with HTML elements).
- Place it where the project places components — **match the existing layout**: feature folders (`src/features/users/components/UserCard.vue`) for non-trivial apps, or flat-by-type (`src/components/UserCard.vue`) for small ones. Detect from where siblings live.

## Anatomy — `<script setup lang="ts">`

Order: imports → props → emits/model → local state → computed → watchers → lifecycle → functions.

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { User } from '@/types/user'

const props = withDefaults(
  defineProps<{
    user: User
    dense?: boolean
  }>(),
  { dense: false },
)

const emit = defineEmits<{
  edit: [user: User]
  delete: [id: string]
}>()

// two-way binding without a prop+emit pair
const selected = defineModel<boolean>('selected', { default: false })

const fullName = computed(() => `${props.user.firstName} ${props.user.lastName}`)
</script>

<template>
  <article class="user-card" :class="{ 'user-card--dense': dense }">
    <input v-model="selected" type="checkbox" :aria-label="`Select ${fullName}`" />
    <h3>{{ fullName }}</h3>
    <slot name="actions" :user="user">
      <button type="button" @click="emit('edit', user)">Edit</button>
    </slot>
  </article>
</template>

<style scoped>
.user-card {
  display: flex;
  gap: var(--space-2, 0.5rem);
  padding: var(--space-3, 0.75rem);
}
.user-card--dense {
  padding: var(--space-1, 0.25rem);
}
</style>
```

## Conventions

- **Typed `defineProps`/`defineEmits`** via the generic form (compile-time types). `withDefaults` for optional prop defaults.
- **`defineModel`** for two-way binding (Vue 3.4+) instead of a manual `modelValue` prop + `update:modelValue` emit.
- **Props are read-only** — never mutate `props.x`; emit an event or use a local `ref`/`computed`.
- **Emits are typed and past-tense-ish nouns/verbs** (`edit`, `delete`, `submit`); list them in `defineEmits`.
- **Slots** for composition; provide a default via `<slot>` fallback content; pass scoped slot props where the parent needs context.
- **Accessibility**: real `<button>`/`<a>` (not `<div @click>`), `aria-*` on icon-only controls, labels on inputs.
- **Keep components presentational** — data fetching lives in composables/queries ([QUERY-001](../data/QUERY-001-tanstack-query.md)), not inline in components.

## Don't

- Don't use the Options API or `export default {}` — `<script setup>` only.
- Don't mutate props, reach into a parent, or use a global event bus.
- Don't hard-code a styling system — match the project's (Tailwind classes, a UI lib's components, or scoped CSS). See [STYLE-001](../styling/STYLE-001-conventions.md).

## See also

- [COMPONENT-002-forms.md](./COMPONENT-002-forms.md) · [STYLE-001](../styling/STYLE-001-conventions.md) · [COMPOSABLE-001](../composables/COMPOSABLE-001-conventions.md)
