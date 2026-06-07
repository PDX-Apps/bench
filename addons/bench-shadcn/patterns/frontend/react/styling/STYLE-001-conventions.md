---
mode: append
---

## shadcn/ui theming (this project uses bench-shadcn)

Styling is **Tailwind + the shadcn token system**. Theme via the CSS variables in `globals.css` (`--background`, `--foreground`, `--primary`, `--radius`, …); components read them through Tailwind (`bg-background`, `text-primary`).

- Use semantic token utilities (`bg-card`, `text-muted-foreground`, `border-input`) — not raw colors.
- Dark mode: the `.dark` class overrides the same variables; toggle it on `<html>`.
- Merge/override classes with `cn()` (clsx + tailwind-merge).
