---
mode: append
---

## Tailwind CSS v4 (this project uses bench-tailwind)

Style with **utility classes** in `class`/`className`; don't emit `<style scoped>` / CSS-Modules blocks except for genuinely dynamic values.

**Setup is CSS-first (v4 — no `tailwind.config.js`):**

```css
/* app.css */
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-primary: oklch(0.62 0.19 260);
  --color-on-primary: white;
  --radius: 0.375rem;
}
```

- v4 uses the `@tailwindcss/vite` plugin + `@import "tailwindcss"`. Design tokens live in `@theme {}` (CSS), not a JS config.
- Compose utilities in markup; extract repeated utility clusters into **components**, not `@apply` soup.
- **Dark mode** via the `dark:` variant + a `.dark` class on the root element.
- Conditional classes: merge with a helper — `clsx`/`tailwind-merge` (React `cn()`); Vue `:class` arrays/objects.
- Theme colors reference the `@theme` tokens (`bg-primary`, `text-on-primary`), so theming stays centralized.
