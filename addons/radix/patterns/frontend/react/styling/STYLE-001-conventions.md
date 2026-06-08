---
mode: append
---

## Styling Radix (this project uses radix)

Radix primitives are unstyled — style them with the project’s existing system (Tailwind or CSS Modules, per STYLE-001). Use `data-state` attributes Radix sets (`[data-state="open"]`) for state-based styles, and `data-[state=open]:` Tailwind variants.

- Theme via CSS variables / your Tailwind config — Radix imposes no token system.
- Animate on `data-state` (open/closed) with CSS transitions/keyframes.
