---
mode: append
---

## shadcn/ui (this project uses shadcn)

UI is built from **shadcn/ui** components you own (Radix primitives + Tailwind + CVA) — in this project they live under `<!--bench:var:ui_dir;default:@/components/ui-->`. Compose these — don't hand-roll buttons/dialogs/inputs.

```tsx
import { Button } from '<!--bench:var:ui_dir;default:@/components/ui-->/button'
import { Dialog, DialogContent, DialogTrigger } from '<!--bench:var:ui_dir;default:@/components/ui-->/dialog'

export function EditUserDialog() {
  return (
    <Dialog>
      <DialogTrigger asChild><Button variant="outline">Edit</Button></DialogTrigger>
      <DialogContent>{/* form */}</DialogContent>
    </Dialog>
  )
}
```

- **Add primitives with the CLI**: `npx shadcn@latest add button dialog input` — they land in your ui directory and are yours to edit.
- **Variants** via the component's CVA `variant`/`size` props; merge extra classes with `cn()` (`<!--bench:var:utils_dir;default:@/lib/utils-->`).
- **Forms**: shadcn `Form` wraps react-hook-form + Zod (`zodResolver`) — use it for validated forms.
- Compose feature components from these primitives; only drop to raw elements when no primitive fits.
