---
mode: append
---

## Chakra UI (this project uses bench-chakra)

Compose UI from Chakra components (`Button`, `Dialog`, `Input`, `Field`) from `@chakra-ui/react`. Do not hand-roll equivalents.

```tsx
import { Button, Dialog, Portal } from "@chakra-ui/react"

export function EditUserDialog() {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild><Button variant="outline">Edit</Button></Dialog.Trigger>
      <Portal><Dialog.Backdrop /><Dialog.Positioner><Dialog.Content>{/* form */}</Dialog.Content></Dialog.Positioner></Portal>
    </Dialog.Root>
  )
}
```

- Use **style props** for layout/spacing (`<Box p="4" display="flex" gap="2">`) and component `variant`/`size`/`colorPalette` props for variants.
- Layout with `Box`/`Stack`/`Flex`/`Grid`; forms with `Field` + `Input` (+ react-hook-form + Zod).
- Compose from Chakra primitives; match the project’s Chakra major version (v3 uses the slot/`.Root` API shown above).
