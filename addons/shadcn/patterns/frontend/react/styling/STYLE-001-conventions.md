---
mode: append
---

## shadcn/ui theming (this project uses shadcn)

Styling is **Tailwind + the shadcn token system**. Theme through the CSS variables defined in the global stylesheet (`globals.css` / `index.css`), read by components via semantic Tailwind utilities — not raw colors.

### The token variables

```css
:root {
  --background: …; --foreground: …;
  --primary: …; --primary-foreground: …;
  --muted: …; --muted-foreground: …;
  --accent: …; --destructive: …;
  --border: …; --input: …; --ring: …;
  --radius: 0.5rem;
}
.dark { --background: …; --foreground: …; /* same names, dark values */ }
```

Components read them through utilities: `bg-background`, `text-foreground`, `bg-card`, `text-muted-foreground`, `border-input`, `ring-ring`. Use these semantic utilities — never raw `bg-zinc-900` etc. — so light/dark and re-theming stay centralized. (Newer setups define these with `oklch()` and wire them via Tailwind v4's `@theme inline`; older ones use the `tailwind.config` `theme.extend.colors` mapping — match the project.)

### Conventions

- **`components.json`** holds the project's choices (`style`, `baseColor`, `cssVariables`, path aliases) and drives the CLI — don't fight it.
- **Dark mode**: the `.dark` class overrides the same variables; toggle it on `<html>` (typically via `next-themes`).
- **Re-theme** by editing the CSS variables (or applying a registry theme) — not by overriding component internals.
- Merge/override classes with **`cn()`**; one-off tweaks go through the className, not edits to deep selectors.

### Don't

- Don't hard-code palette colors (`bg-blue-600`) — use semantic tokens (`bg-primary`).
- Don't duplicate the variable set ad hoc — light + `.dark` in one place is the source of truth.
- Don't override component CSS from outside — adjust the owned component or its `cn()` classes.
