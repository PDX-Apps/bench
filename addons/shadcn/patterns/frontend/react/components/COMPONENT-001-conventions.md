---
mode: append
---

## shadcn/ui (this project uses shadcn)

UI is built from **shadcn/ui** components you **own** (Radix primitives + Tailwind + CVA) — copied into the repo under `<!--bench:var:ui_dir;default:@/components/ui-->`, yours to edit. Compose these; don't hand-roll buttons/dialogs/inputs, and don't `npm install` them.

### Add components with the CLI

```bash
npx shadcn@latest add button dialog input form table   # lands files in your ui dir
```

(Project init is `npx shadcn@latest init`, which writes `components.json`.) Catalog you'll reach for: `Button`, `Input`, `Textarea`, `Select`, `Checkbox`, `Dialog`, `Sheet`, `DropdownMenu`, `Popover`, `Command` (cmdk palette), `Table`, `Form`, `Tabs`, `Card`, `Badge`, `Sonner`/`Toast`.

```tsx
import { Button } from '<!--bench:var:ui_dir;default:@/components/ui-->/button'
import { Dialog, DialogContent, DialogTrigger } from '<!--bench:var:ui_dir;default:@/components/ui-->/dialog'

export function EditOrderDialog() {
  return (
    <Dialog>
      <DialogTrigger asChild><Button variant="outline">Edit</Button></DialogTrigger>
      <DialogContent>{/* form */}</DialogContent>
    </Dialog>
  )
}
```

### Variants + class merging

Variants come from each component's **CVA** config (`variant`, `size` props). Merge extra/conditional classes with **`cn()`** (clsx + tailwind-merge) from `<!--bench:var:utils_dir;default:@/lib/utils-->` — never string-concat classes.

### Forms — react-hook-form + Zod via the `Form` components

shadcn's `Form` wraps RHF; compose `FormField` (a `Controller`) with `FormItem`/`FormLabel`/`FormControl`/`FormMessage`:

```tsx
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '<!--bench:var:ui_dir;default:@/components/ui-->/form'
import { Input } from '<!--bench:var:ui_dir;default:@/components/ui-->/input'

const form = useForm({ resolver: zodResolver(orderSchema), defaultValues: { reference: "" } })

<Form {...form}>
  <form onSubmit={form.handleSubmit(onSubmit)}>
    <FormField control={form.control} name="reference" render={({ field }) => (
      <FormItem>
        <FormLabel>Reference</FormLabel>
        <FormControl><Input {...field} /></FormControl>
        <FormMessage />   {/* shows the Zod error for this field */}
      </FormItem>
    )} />
  </form>
</Form>
```

### Data tables

Tables are **TanStack Table** (headless) composed with shadcn's `Table` primitives — define `columns`, feed `data`, and build a reusable `DataTable`. Don't hand-roll sorting/pagination.

### Don't

- Don't `npm install` shadcn components or treat the `ui/` files as untouchable vendor code — they're yours; edit them.
- Don't string-concat classes — use `cn()`.
- Don't roll your own form field wiring — use `FormField`/`FormMessage` so Zod errors surface correctly.
