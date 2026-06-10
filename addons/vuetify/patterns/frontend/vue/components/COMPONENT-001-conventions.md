---
mode: append
---

## Vuetify (this project uses vuetify)

Compose UI from **Vuetify** Material components (`v-btn`, `v-text-field`, `v-select`, `v-autocomplete`, `v-dialog`, `v-data-table`, `v-form`, `v-card`, `v-snackbar`, …) — don't hand-roll equivalents. Components are registered by the Vuetify plugin (tree-shaken via `vite-plugin-vuetify`); match the project setup.

### Variants via props

Use props for the look: `variant` (`elevated`/`flat`/`tonal`/`outlined`/`text`/`plain`), `color`, `size`, `density`:

```vue
<v-btn variant="tonal" color="primary" @click="open = true">Edit</v-btn>
```

### Layout

Grid is `v-container` / `v-row` / `v-col` (12-col, responsive `cols`/`md` props); `v-spacer` pushes items apart.

### Dialog

```vue
<v-dialog v-model="open" max-width="480">
  <template #activator="{ props }"><v-btn v-bind="props">Edit</v-btn></template>
  <v-card title="Edit order">
    <v-card-text><!-- v-text-field, v-form --></v-card-text>
  </v-card>
</v-dialog>
```

### Forms — `v-form` + `:rules`

Rules are an array of functions returning `true` or an error string. Validate on submit, or programmatically through the form ref:

```vue
<script setup lang="ts">
import { ref } from "vue"
const form = ref()
const reference = ref("")
async function onSubmit() {
  const { valid } = await form.value.validate()
  if (valid) { /* … */ }
}
</script>

<template>
  <v-form ref="form" validate-on="submit" @submit.prevent="onSubmit">
    <v-text-field v-model="reference" label="Reference" :rules="[v => !!v || 'Required']" />
    <v-btn type="submit" color="primary">Save</v-btn>
  </v-form>
</template>
```

Bridge a Zod schema with a rule adapter (`v => schema.safeParse(v).success || message`).

### Data tables — `v-data-table`

```vue
<v-data-table :headers="headers" :items="orders" :search="search" item-value="id" />
```

`headers` is `{ title, key, sortable, align }[]`; `v-data-table` handles sorting, search, and pagination. Use `v-data-table-server` for server-side paging.

### Other

- **Toasts**: `v-snackbar v-model="show"`.
- Customize via props and slots (`#prepend`, `#item.<key>`), not deep `.v-*` CSS.

### Don't

- Don't hand-roll inputs/tables/dialogs Vuetify ships.
- Don't override `.v-*` internal CSS — use props, slots, and theme tokens.
- Don't hard-code colors — use the theme palette (see theming).
