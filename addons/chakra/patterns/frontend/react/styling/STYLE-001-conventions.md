---
mode: append
---

## Chakra theming (this project uses chakra)

Theme through the Chakra **system** (v3), not ad-hoc CSS. Build it once with `createSystem` and provide it at the root:

```tsx
import { ChakraProvider, createSystem, defaultConfig, defineConfig } from "@chakra-ui/react"

const config = defineConfig({
  theme: {
    tokens: { colors: { brand: { 500: { value: "#2563eb" } } } },
    semanticTokens: { colors: { "bg.canvas": { value: { base: "white", _dark: "{colors.gray.900}" } } } },
  },
})
const system = createSystem(defaultConfig, config)

<ChakraProvider value={system}>{/* app */}</ChakraProvider>
```

### Reference tokens, never raw hex

Use semantic tokens + `colorPalette` through style props:

```tsx
<Box bg="bg.subtle" color="fg" borderColor="border" />
<Button colorPalette="blue" />   // resolves to blue.* / the palette's semantic slots
```

Semantic tokens (`bg`, `fg`, `bg.subtle`, `fg.muted`, `border`) resolve per color mode automatically; `colorPalette` recolors a whole component from one prop.

### Dark mode

Color mode runs on **next-themes** via the color-mode snippet (`ColorModeProvider`); read/toggle with `useColorMode()` / `useColorModeValue()`. Semantic tokens carry their `_dark` value, so styling written against tokens needs no per-mode branching.

### Recipes for component variants

Define reusable component variants with **recipes** (`defineRecipe` / `defineSlotRecipe`) in the config — not scattered conditional style props. Spacing/sizing also come from the token scale on style props (`p="4"`, `gap="2"`); avoid ad-hoc CSS.

### Don't

- Don't use raw hex in markup — use tokens / `semanticTokens` / `colorPalette`.
- Don't branch styles on color mode by hand — put the `_dark` value in a semantic token.
- Don't reach for `sx`/inline CSS for variants — use recipes + style props.
