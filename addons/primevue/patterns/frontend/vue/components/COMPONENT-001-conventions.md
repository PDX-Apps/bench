---
mode: append
---

## PrimeVue (this project uses primevue)

Compose UI from PrimeVue components — import per-component (`primevue/button`, `primevue/dialog`, `primevue/datatable`). Do not hand-roll buttons/dialogs/tables.

```vue
<script setup lang="ts">
import Button from "primevue/button"
import Dialog from "primevue/dialog"
import { ref } from "vue"
const open = ref(false)
</script>

<template>
  <Button label="Edit" severity="secondary" @click="open = true" />
  <Dialog v-model:visible="open" modal header="Edit user"><!-- form --></Dialog>
</template>
```

- Use component props (`severity`, `size`, `outlined`) for variants; customize internals via **PassThrough (`pt`)**, not by overriding deep CSS.
- DataTable/Form components are first-class — prefer them over custom tables/inputs.
- Register components globally or import locally to match the project; check existing usage.
