---
mode: append
---

## Tailwind CSS v4 (this project uses tailwind)

Style with **utility classes** in `class`; don't emit `<style scoped>` / CSS-module blocks except for genuinely dynamic values. Tailwind v4 is **CSS-first** — design tokens live in CSS, not a JS config.

### Setup (CSS-first — no `tailwind.config.js`)

```css
/* app.css */
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));   /* class-based dark mode */

@theme {
  --color-primary: oklch(0.62 0.19 260);
  --color-on-primary: white;
  --radius: 0.375rem;
  --font-display: "Inter", sans-serif;
}
```

v4 uses the `@tailwindcss/vite` plugin (or `@tailwindcss/postcss`) + `@import "tailwindcss"`. Tokens in `@theme {}` **generate utilities** — `--color-primary` → `bg-primary`/`text-primary`/`border-primary`, `--font-display` → `font-display`. They're also exposed as CSS variables (`var(--color-primary)`).

### Composing utilities

- Build in markup: `class="flex items-center gap-2 rounded bg-primary px-4 py-2 text-on-primary"`.
- **Variants stack**: `hover:bg-primary/90 md:flex dark:bg-surface focus-visible:ring group-hover:opacity-100`.
- **State/relationship variants**: `data-[state=open]:`, `aria-[expanded]:`, `has-[:checked]:`, `peer-*`/`group-*`.
- **Container queries** are built in: `@container` on the parent, `@md:grid-cols-2` on children.
- **Arbitrary values** when a token doesn't exist: `bg-[#1da1f2]`, `grid-cols-[1fr_320px]`, `[mask-type:luminance]`.

### Extracting + custom utilities

- Prefer extracting a repeated cluster into a **component** (a Vue component), not `@apply` soup.
- For a genuine reusable utility, use **`@utility`** (v4's replacement for `@layer utilities`):

```css
@utility card { @apply rounded bg-white p-4 shadow; }
```

- `@apply` still works inside CSS for the occasional case; `theme(--color-primary)` / `var(--color-primary)` reach tokens in CSS.

### Dark mode + conditional classes

- **Dark mode**: the `dark:` variant + a `.dark` class on the root (wired via `@custom-variant dark` above).
- **Conditional classes**: Vue `:class` arrays/objects; for computed merges use `tailwind-merge` so later utilities win.

### Don't

- Don't add a `tailwind.config.js` for tokens — put them in `@theme {}`.
- Don't hard-code hex in markup where a `@theme` token (`bg-primary`) exists.
- Don't `@apply` long chains to fake components — extract a component instead.
- Don't string-concat conditional classes — use `:class` / `tailwind-merge`.
