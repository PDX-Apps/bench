---
mode: append
---

## MUI theming (this project uses mui)

Theme via `createTheme({ palette, typography, ... })` + `<ThemeProvider>`. Reference theme tokens through `sx` (`sx={{ color: "primary.main", p: 2 }}`) and component `color` props — never raw hex.

- Dark mode: a second theme (`palette.mode: "dark"`) or `colorSchemes`; toggle via the provider.
- Spacing via the theme spacing scale (`sx={{ p: 2, mt: 1 }}`); avoid ad-hoc pixel CSS.
