---
mode: append
---

## Vuetify (this project uses bench-vuetify)

Compose UI from Vuetify Material components (`<v-btn>`, `<v-dialog>`, `<v-text-field>`, `<v-data-table>`). Do not hand-roll equivalents.

```vue
<script setup lang="ts">
import { ref } from "vue"
const open = ref(false)
</script>

<template>
  <v-btn variant="tonal" @click="open = true">Edit</v-btn>
  <v-dialog v-model="open" max-width="480">
    <v-card title="Edit user"><!-- v-text-field, v-form --></v-card>
  </v-dialog>
</template>
```

- Use component props (`variant`, `color`, `density`, `size`) for styling; lay out with the grid (`v-container`/`v-row`/`v-col`).
- Forms: `v-form` + `v-text-field` `:rules` (bridge Zod via a rule adapter if the project does).
- Components are globally registered by the Vuetify plugin — no per-file imports needed (match the project setup).
