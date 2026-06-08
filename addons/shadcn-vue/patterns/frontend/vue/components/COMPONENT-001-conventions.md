---
mode: append
---

## shadcn-vue (this project uses shadcn-vue)

UI is built from **shadcn-vue** components you own under `src/components/ui/` (Reka UI primitives + Tailwind + CVA). Compose these — don't hand-roll buttons/dialogs/inputs.

```vue
<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogTrigger } from '@/components/ui/dialog'
</script>

<template>
  <Dialog>
    <DialogTrigger as-child><Button variant="outline">Edit</Button></DialogTrigger>
    <DialogContent><!-- form --></DialogContent>
  </Dialog>
</template>
```

- **Add primitives with the CLI**: `npx shadcn-vue@latest add button dialog input` — they land in `components/ui/` and are yours to edit.
- **Variants** come from the component's CVA config (`variant`, `size` props); merge extra classes with `cn()` (`@/lib/utils`).
- **Forms**: shadcn-vue Form components wrap vee-validate + Zod — use them for validated forms.
- Compose feature components from `ui/` primitives; only drop to raw elements when no primitive fits.
