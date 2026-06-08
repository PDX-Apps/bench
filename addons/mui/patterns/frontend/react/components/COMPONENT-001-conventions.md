---
mode: append
---

## MUI (this project uses mui)

Compose UI from MUI components (`Button`, `Dialog`, `TextField`, `DataGrid`) from `@mui/material`. Do not hand-roll equivalents.

```tsx
import { Button, Dialog, DialogTitle, DialogContent } from "@mui/material"
import { useState } from "react"

export function EditUserDialog() {
  const [open, setOpen] = useState(false)
  return (
    <>
      <Button variant="outlined" onClick={() => setOpen(true)}>Edit</Button>
      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>Edit user</DialogTitle>
        <DialogContent>{/* TextField, form */}</DialogContent>
      </Dialog>
    </>
  )
}
```

- Use component props (`variant`, `color`, `size`) for variants; one-off styles via the **`sx`** prop (theme-aware), not inline `style`.
- Layout with `Box`/`Stack`/`Grid`; forms with `TextField` (+ react-hook-form `Controller` + Zod).
- Reusable restyles via `styled()`; avoid deep CSS overrides.
