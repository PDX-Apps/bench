---
mode: append
---

## Radix Primitives (this project uses radix)

Build accessible UI from **unstyled** Radix primitives — they own behavior, focus management, keyboard nav, and ARIA; you own the look. Install the single `radix-ui` package and import from it (recommended — avoids per-package version drift); the individual `@radix-ui/react-*` packages still work if a project already uses them.

Catalog you'll reach for: `Dialog`, `AlertDialog`, `DropdownMenu`, `Popover`, `Tooltip`, `HoverCard`, `Select`, `Tabs`, `Accordion`, `Collapsible`, `Checkbox`, `RadioGroup`, `Switch`, `Slider`, `Toast`, `Toggle`, `ScrollArea`, `Avatar`.

### Compound parts + `asChild`

Each primitive is a set of parts (`.Root`/`.Trigger`/`.Content`/…). Use `asChild` to render *your* element (or styled component) instead of Radix's default, merging behavior onto it:

```tsx
import { Dialog } from "radix-ui"
import styles from "./EditOrderDialog.module.css"

export function EditOrderDialog() {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild><button className={styles.btn}>Edit</button></Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className={styles.overlay} />
        <Dialog.Content className={styles.content}>
          <Dialog.Title>Edit order</Dialog.Title>
          <Dialog.Description>Update the order details.</Dialog.Description>
          {/* form */}
          <Dialog.Close asChild><button>Close</button></Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
```

### Conventions

- **`Portal`** for any overlay (Dialog/DropdownMenu/Popover/Tooltip/Select) so it escapes parent `overflow`/stacking contexts.
- **Controlled when you need it**: `open` + `onOpenChange` (Dialog/Popover), `value` + `onValueChange` (Tabs/Select/RadioGroup); otherwise let the primitive manage its own state.
- **Accessibility is built in** — provide the required parts (`Dialog.Title`, a label for inputs) and don't reimplement focus traps, escape handling, or roving tabindex.
- **`asChild`** to attach a primitive part to your own component without an extra wrapper element.
- For **pre-styled** Radix-based components (Radix + Tailwind, copy-into-repo), the project may use the shadcn track instead — match whichever it has.

### Don't

- Don't hand-build dropdowns/dialogs/tooltips — the a11y is the hard part Radix already solves.
- Don't forget `Portal` on overlays, or the required label parts (`Title`/`Description`).
- Don't fight the primitive's controlled/uncontrolled model — pick one per instance.
