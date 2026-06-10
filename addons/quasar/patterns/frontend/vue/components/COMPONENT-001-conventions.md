---
mode: append
---

## Quasar (this project uses quasar)

Compose UI from **Quasar** components (`q-btn`, `q-input`, `q-select`, `q-dialog`, `q-table`, `q-form`, `q-card`, …) — don't hand-roll equivalents. Components and directives are provided globally by the Quasar plugin (no per-file imports); match the project's setup.

### Variants via props + the `$q` instance

```vue
<script setup lang="ts">
import { useQuasar } from "quasar"
const $q = useQuasar()
</script>

<template>
  <q-btn label="Save" color="primary" unelevated />
  <q-btn label="Cancel" color="primary" flat @click="$q.notify('Cancelled')" />
</template>
```

Use props (`flat`/`outline`/`unelevated`, `color`, `size`, `dense`) for the look. `useQuasar()` exposes the **plugin services** — `$q.notify(...)`, `$q.dialog(...)`, `$q.loading.show()` — which must be enabled in `quasar.config` (`framework.plugins`).

### Forms — `q-form` + `:rules`

Validation rules are an array of functions returning `true` or an error string. Wire submit through `q-form`:

```vue
<script setup lang="ts">
import { ref } from "vue"
const form = ref()
const reference = ref("")
async function onSubmit() {
  if (await form.value.validate()) { /* models are valid */ }
}
</script>

<template>
  <q-form ref="form" @submit.prevent="onSubmit" class="q-gutter-md">
    <q-input
      v-model="reference"
      label="Reference"
      lazy-rules
      :rules="[val => !!val || 'Reference is required']"
    />
    <q-btn label="Save" type="submit" color="primary" />
  </q-form>
</template>
```

`form.value.validate()` returns a promise; `resetValidation()` clears it. To reuse a Zod schema, wrap it in a rule adapter (`val => schema.safeParse(val).success || message`).

### Tables — `q-table`

```vue
<q-table
  :rows="orders"
  :columns="columns"
  row-key="id"
  selection="multiple"
  v-model:selected="selected"
  v-model:pagination="pagination"
  flat bordered
/>
```

`columns` is an array of `{ name, label, field, sortable, align }`; `q-table` handles sorting, pagination, and selection. Use it over a hand-built table.

### Dialogs

Declarative `q-dialog v-model="open">` for custom content, or the programmatic `$q.dialog({ title, message, cancel: true }).onOk(...)` for confirms.

### Don't

- Don't hand-roll inputs/tables/overlays Quasar ships.
- Don't call `$q.notify`/`$q.dialog`/`$q.loading` without enabling the plugin in `quasar.config`.
- Don't reach into component internal CSS — use props, slots, and brand tokens (see theming).
