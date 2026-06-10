---
mode: append
---

## Styling Radix (this project uses radix)

Radix primitives ship **no styles** — style them with the project's existing system (Tailwind or CSS Modules). Radix imposes no token system; theme through your own CSS variables / Tailwind config.

### Style from the state Radix exposes

Primitives set `data-*` attributes you target instead of tracking state yourself:

- **`data-state`** — `open`/`closed`, `checked`/`unchecked`, `active`/`inactive`.
- **`data-side`** / **`data-align`** — placement of poppers (Popover/DropdownMenu/Tooltip).
- **`data-orientation`**, **`data-disabled`**, **`data-highlighted`** (menu/select items under keyboard/pointer).

```css
.content[data-state="open"]  { animation: fadeIn 150ms ease; }
.content[data-state="closed"]{ animation: fadeOut 150ms ease; }
```

```tsx
// Tailwind variants for the same attributes:
<Popover.Content className="data-[state=open]:animate-in data-[side=top]:slide-in-from-bottom-2" />
```

### Size/position with the exposed CSS variables

Radix poppers/collapsibles publish CSS custom properties — use them instead of magic numbers:

- `--radix-popper-available-width` / `--radix-popper-available-height` — clamp content to the viewport.
- `--radix-dropdown-menu-trigger-width` (and per-primitive equivalents) — match the trigger's width.
- `--radix-accordion-content-height` / `--radix-collapsible-content-height` — animate open/close to the measured height.

```css
.menu-content { max-height: var(--radix-popper-available-height); width: var(--radix-dropdown-menu-trigger-width); }
```

### Don't

- Don't track open/checked state in React just to style it — read `data-state`.
- Don't hard-code popper sizes/positions — use the `--radix-*` variables.
- Don't import a Radix theme — there isn't one; styling is entirely yours.
