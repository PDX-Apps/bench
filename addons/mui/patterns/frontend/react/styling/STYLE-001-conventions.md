---
mode: append
---

## MUI theming (this project uses mui)

Styling flows through the **theme**, not ad-hoc CSS. Define it once with `createTheme(...)` and apply it at the root with `ThemeProvider` + `CssBaseline`:

```tsx
import { createTheme, ThemeProvider } from "@mui/material/styles"
import CssBaseline from "@mui/material/CssBaseline"

const theme = createTheme({
  palette: { primary: { main: "#2563eb" }, secondary: { main: "#7c3aed" } },
  shape: { borderRadius: 8 },
  typography: { fontFamily: "Inter, sans-serif" },
})

<ThemeProvider theme={theme}><CssBaseline />{/* app */}</ThemeProvider>
```

### Reference tokens, never raw hex

Read theme values through `sx` and component props — `color`, `bgcolor`, `borderColor` resolve palette paths:

```tsx
<Box sx={{ bgcolor: "background.paper", color: "text.primary", borderColor: "divider" }} />
<Button color="primary" />   // primary.main / .light / .dark / .contrastText
```

Palette groups: `primary`/`secondary`/`error`/`warning`/`info`/`success`, plus `background`, `text`, `divider`, `action`. Add brand colors to the palette; don't scatter hex in markup.

### Dark mode — `colorSchemes` + CSS theme variables (v6/v7)

The modern approach generates CSS variables for both schemes and toggles via a class, avoiding a flash and a second provider:

```tsx
const theme = createTheme({
  colorSchemes: { light: true, dark: true },
  cssVariables: { colorSchemeSelector: "class" },   // <html class="dark">
})
```

Toggle with the `useColorScheme()` hook (`const { mode, setMode } = useColorScheme()` → `setMode("dark" | "light" | "system")`). For a single fixed theme, `palette: { mode: "dark" }` still works.

### Spacing + global component defaults

- **Spacing** is an 8px scale via the `sx` shorthand: `sx={{ p: 2, mt: 1, gap: 2 }}` (= 16/8/16px). Don't hard-code pixels for what the scale covers.
- **App-wide component tweaks** live in `theme.components` — set `defaultProps` (e.g. all buttons `disableElevation`) and `styleOverrides` once, instead of repeating props/`sx` everywhere:

```tsx
createTheme({
  components: {
    MuiButton: { defaultProps: { disableElevation: true }, styleOverrides: { root: { textTransform: "none" } } },
  },
})
```

### Reusable styled components

Use `styled()` (from `@mui/material/styles`) for a restyle you reuse; it gets theme access in the callback:

```tsx
import { styled } from "@mui/material/styles"
const Toolbar = styled("div")(({ theme }) => ({ display: "flex", gap: theme.spacing(1), padding: theme.spacing(2) }))
```

### Don't

- Don't hard-code colors, radii, or pixel spacing — use palette/shape/spacing tokens.
- Don't ship per-component CSS overrides for what `theme.components` (defaultProps/styleOverrides) should set globally.
- Don't run two themes by hand for dark mode — use `colorSchemes` + `useColorScheme()`.
