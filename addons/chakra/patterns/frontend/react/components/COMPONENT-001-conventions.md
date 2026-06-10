---
mode: append
---

## Chakra UI (this project uses chakra)

Compose UI from **Chakra v3** components (`@chakra-ui/react`) — don't hand-roll buttons, inputs, dialogs, or menus. v3 uses a **compound/slot API** (parts under `.Root`).

Catalog: `Button`, `Input`/`Textarea`/`NativeSelect`/`Select`, `Field`, `Checkbox`/`Switch`/`RadioGroup`, `Dialog`, `Drawer`, `Menu`, `Popover`, `Tooltip`, `Tabs`, `Table`, `Toaster` (via `createToaster`). Layout: `Box`, `Stack`/`HStack`/`VStack`, `Flex`, `Grid`/`SimpleGrid`, `Container`.

### Style props + variants

Use **style props** for layout/spacing and `variant`/`size`/`colorPalette` for the look:

```tsx
<Box p="4" display="flex" gap="2" rounded="md">
  <Button variant="solid" colorPalette="blue" size="sm">Save</Button>
</Box>
```

### Dialog (compound parts + Portal)

```tsx
import { Button, Dialog, Portal } from "@chakra-ui/react"

export function EditOrderDialog() {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild><Button variant="outline">Edit</Button></Dialog.Trigger>
      <Portal>
        <Dialog.Backdrop />
        <Dialog.Positioner>
          <Dialog.Content>
            <Dialog.Header><Dialog.Title>Edit order</Dialog.Title></Dialog.Header>
            <Dialog.Body>{/* form */}</Dialog.Body>
            <Dialog.CloseTrigger asChild><Button variant="ghost">Close</Button></Dialog.CloseTrigger>
          </Dialog.Content>
        </Dialog.Positioner>
      </Portal>
    </Dialog.Root>
  )
}
```

### Forms — `Field` + react-hook-form + Zod

```tsx
import { Field, Input } from "@chakra-ui/react"

<Field.Root invalid={!!errors.reference}>
  <Field.Label>Reference</Field.Label>
  <Input {...register("reference")} />
  <Field.ErrorText>{errors.reference?.message}</Field.ErrorText>
</Field.Root>
```

Wire validation with `react-hook-form` + `zodResolver`; `Field.Root invalid` + `Field.ErrorText` surface the message.

### Snippets

Chakra v3 ships composed helpers as **snippets** you copy in via the CLI (`npx @chakra-ui/cli snippet add`) — the `Provider`, color-mode toggle, and `toaster` come from there. Use the snippet'd `toaster` for notifications rather than hand-building one.

### Don't

- Don't use v2 single-component dialog/menu APIs — v3 is compound (`.Root`/`.Trigger`/`.Content`).
- Don't wrap overlays without `Portal`.
- Don't hard-code colors/spacing — use `colorPalette`, semantic tokens, and the spacing scale (see theming).
