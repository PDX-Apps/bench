---
mode: append
---

## MUI (this project uses mui)

Compose UI from **Material UI** components (`@mui/material`) — don't hand-roll buttons, inputs, dialogs, menus, or tables. Use tree-shakeable named imports.

```tsx
import { Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Stack } from "@mui/material"
```

Reach for the right component: `Button`, `TextField`, `Select`, `Autocomplete`, `Checkbox`/`Switch`/`Radio`, `Dialog`, `Menu`, `Tabs`, `Snackbar`+`Alert` (toasts), `Tooltip`, `Chip`. For data tables use **`DataGrid`** from `@mui/x-data-grid` (sorting/filtering/pagination built in) rather than a hand-built `<Table>`. Icons come from `@mui/icons-material`.

### Variants via props, one-off styles via `sx`

Use component props (`variant`, `color`, `size`) for the built-in look; use the **`sx`** prop for one-off, theme-aware styling — never inline `style`. `sx` reads theme tokens and supports responsive arrays/objects:

```tsx
<Button variant="contained" color="primary" size="small" sx={{ mt: 2, px: 3 }}>Save</Button>
<Box sx={{ display: "flex", gap: 2, color: "text.secondary", p: { xs: 1, md: 2 } }} />
```

`Box`/`Stack`/`Typography`/`Grid` also expose common style props directly (`<Stack mt={1} />`).

### Layout

Lay out with `Box` (generic), `Stack` (1-D flex with `spacing`), `Container` (page width), and **`Grid`** for 2-D. In MUI v7 `Grid` uses the **`size`** prop (this was `Grid2` in v6):

```tsx
import Grid from "@mui/material/Grid"
<Grid container spacing={2}>
  <Grid size={{ xs: 12, md: 6 }}>…</Grid>
  <Grid size={{ xs: 12, md: 6 }}>…</Grid>
</Grid>
```

### Controlled dialog

```tsx
import { useState } from "react"
import { Button, Dialog, DialogTitle, DialogContent, DialogActions } from "@mui/material"

export function EditOrderDialog() {
  const [open, setOpen] = useState(false)
  return (
    <>
      <Button variant="outlined" onClick={() => setOpen(true)}>Edit</Button>
      <Dialog open={open} onClose={() => setOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Edit order</DialogTitle>
        <DialogContent>{/* form */}</DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" type="submit">Save</Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
```

### Forms — react-hook-form `Controller` + Zod

Wrap `TextField` (and `Select`, etc.) with RHF's `Controller`; surface validation via `error` + `helperText`:

```tsx
import { useForm, Controller } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { TextField } from "@mui/material"

const { control, handleSubmit } = useForm({ resolver: zodResolver(orderSchema) })

<Controller
  name="reference"
  control={control}
  render={({ field, fieldState }) => (
    <TextField {...field} label="Reference" error={!!fieldState.error} helperText={fieldState.error?.message} />
  )}
/>
```

### Customizing + extracting

- Customize a component's internal parts via **`slotProps`** (e.g. `slotProps={{ paper: { sx: {...} } }}`) — not deep CSS selectors, and not the deprecated `componentsProps`.
- Extract reusable restyles with **`styled()`** from `@mui/material/styles` (theme-aware); don't copy-paste `sx` blobs across components.

### Don't

- Don't hand-roll components MUI already ships; don't use inline `style` where `sx` works.
- Don't hard-code colors/spacing — use palette tokens (`color="primary.main"`) and the spacing scale (`sx={{ p: 2 }}`).
- Don't reach past the public API into `.MuiX-*` class overrides when a prop, `sx`, `slotProps`, or `styled()` does the job.
