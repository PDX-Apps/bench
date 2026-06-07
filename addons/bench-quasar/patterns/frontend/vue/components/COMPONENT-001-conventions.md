---
mode: append
---

## Quasar (this project uses bench-quasar)

Compose UI from Quasar components (`<q-btn>`, `<q-dialog>`, `<q-input>`, `<q-table>`). Do not hand-roll equivalents.

```vue
<script setup lang="ts">
import { ref } from "vue"
const open = ref(false)
</script>

<template>
  <q-btn flat label="Edit" @click="open = true" />
  <q-dialog v-model="open"><q-card><!-- q-input, q-form --></q-card></q-dialog>
</template>
```

- Use component props (`flat`, `outline`, `color`, `size`) for variants; use the `$q` instance (`useQuasar()`) for dialogs/notify/loading plugins.
- Forms: `q-form` + `q-input` `:rules`; tables via `q-table`.
- Components/directives are provided by the Quasar plugin (no per-file imports) — match the project setup.
