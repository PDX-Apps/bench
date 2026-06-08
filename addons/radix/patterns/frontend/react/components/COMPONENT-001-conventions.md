---
mode: append
---

## Radix Primitives (this project uses radix)

Build accessible UI from **unstyled** Radix primitives (`@radix-ui/react-dialog`, `-dropdown-menu`, `-popover`, …), styled with the project’s own CSS/Tailwind. Radix gives behavior + a11y; you own the look.

```tsx
import * as Dialog from "@radix-ui/react-dialog"
import styles from "./EditUserDialog.module.css"

export function EditUserDialog() {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild><button className={styles.btn}>Edit</button></Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className={styles.overlay} />
        <Dialog.Content className={styles.content}>
          <Dialog.Title>Edit user</Dialog.Title>
          {/* form */}
          <Dialog.Close asChild><button>Close</button></Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
```

- Use the primitive’s parts (`.Root`/`.Trigger`/`.Content`/…); `asChild` to render your own element/styling.
- Radix handles focus management, keyboard, ARIA — don’t reimplement.
- Style with the project’s system (Tailwind/CSS Modules) — Radix ships no styles. (For pre-styled Radix-based components, see shadcn.)
