---
mode: append
---

## shadcn-vue (this project uses shadcn-vue)

UI is built from **shadcn-vue** components you own (Reka UI primitives + Tailwind + CVA) — in this project they live under `<!--bench:var:ui_dir;default:@/components/ui-->`. Compose these — don't hand-roll buttons/dialogs/inputs.

```vue
<script setup lang="ts">
import { Button } from '<!--bench:var:ui_dir;default:@/components/ui-->/button'
import { Dialog, DialogContent, DialogTrigger } from '<!--bench:var:ui_dir;default:@/components/ui-->/dialog'
</script>

<template>
  <Dialog>
    <DialogTrigger as-child><Button variant="outline">Edit</Button></DialogTrigger>
    <DialogContent><!-- form --></DialogContent>
  </Dialog>
</template>
```

- **Add primitives with the CLI**: `npx shadcn-vue@latest add button dialog input` — they land in your ui directory and are yours to edit.
- **Variants** come from the component's CVA config (`variant`, `size` props); merge extra classes with `cn()` (`<!--bench:var:utils_dir;default:@/lib/utils-->`).
- **Forms**: shadcn-vue Form components wrap vee-validate + Zod — use them for validated forms.
- Compose feature components from these primitives; only drop to raw elements when no primitive fits.
