---
mode: append
---

## shadcn-vue (this project uses shadcn-vue)

UI is built from **shadcn-vue** components you **own** (Reka UI primitives + Tailwind + CVA) — copied into the repo under `<!--bench:var:ui_dir;default:@/components/ui-->`, yours to edit. Compose these; don't hand-roll buttons/dialogs/inputs, and don't `npm install` them.

### Add components with the CLI

```bash
npx shadcn-vue@latest add button dialog input form table   # lands files in your ui dir
```

(Project init is `npx shadcn-vue@latest init`, which writes `components.json`.) Catalog: `Button`, `Input`, `Textarea`, `Select`, `Checkbox`, `Dialog`, `Sheet`, `DropdownMenu`, `Popover`, `Command`, `Table`, `Form`, `Tabs`, `Card`, `Badge`, `Sonner`/`Toast`.

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

### Variants + class merging

Variants come from each component's **CVA** config (`variant`, `size` props). Merge extra/conditional classes with **`cn()`** (clsx + tailwind-merge) from `<!--bench:var:utils_dir;default:@/lib/utils-->` — never string-concat.

### Forms — vee-validate + Zod via the `Form` components

shadcn-vue forms use **vee-validate** with a Zod schema (`toTypedSchema`). Compose `FormField` (bind its `componentField` to the input) with `FormItem`/`FormLabel`/`FormControl`/`FormMessage`:

```vue
<script setup lang="ts">
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '<!--bench:var:ui_dir;default:@/components/ui-->/form'
import { Input } from '<!--bench:var:ui_dir;default:@/components/ui-->/input'

const formSchema = toTypedSchema(z.object({ reference: z.string().min(1, "Required") }))
const form = useForm({ validationSchema: formSchema })
const onSubmit = form.handleSubmit((values) => { /* … */ })
</script>

<template>
  <form @submit="onSubmit">
    <FormField v-slot="{ componentField }" name="reference">
      <FormItem>
        <FormLabel>Reference</FormLabel>
        <FormControl><Input v-bind="componentField" /></FormControl>
        <FormMessage />
      </FormItem>
    </FormField>
    <Button type="submit">Save</Button>
  </form>
</template>
```

### Data tables

Tables are **TanStack Table** (Vue adapter) composed with shadcn-vue's `Table` primitives — define `columns`, feed `data`, build a reusable `DataTable`. Don't hand-roll sorting/pagination.

### Don't

- Don't `npm install` shadcn-vue components or treat the `ui/` files as vendor code — they're yours; edit them.
- Don't string-concat classes — use `cn()`.
- Don't wire form fields by hand — use `FormField` + `FormMessage` so Zod errors surface.
