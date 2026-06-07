---
mode: append
---

## Chakra theming (this project uses bench-chakra)

Theme via the Chakra **system** (`createSystem`/`defaultConfig` tokens) + `<ChakraProvider value={system}>`. Reference semantic tokens through style props (`bg="bg.subtle"`, `color="fg"`, `colorPalette="blue"`) — not raw hex.

- Dark mode: `next-themes`/the color-mode API; semantic tokens resolve per mode.
- Spacing/sizing via the token scale on style props; avoid ad-hoc CSS.
