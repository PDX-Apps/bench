# Styling & theming

Styling is the **most project-specific** decision in a frontend. The rule for generated code: **detect the project's styling system and match it.** This defines the detection order and the zero-config default.

## Detect first — match what the project already does

Inspect `package.json` + a couple of existing components:

| Signal | System | Generate… |
|--------|--------|-----------|
| `tailwindcss` dep + `@tailwind`/`@import "tailwindcss"` | **Tailwind** | utility classes in `className` (`bench-tailwind` addon sharpens this) |
| shadcn/ui components in `components/ui/`, `class-variance-authority` | **shadcn/ui** | its components + `cn()` + CVA variants (`bench-shadcn`) |
| `@mui/*`, `@chakra-ui/*` | **UI library** | the library's components + its theming (`bench-mui`/`bench-chakra`) |
| `*.module.css` imports | **CSS Modules** | `import styles` + `className={styles.x}` |
| `styled-components`/`@emotion` | **CSS-in-JS** | styled components, match the existing approach |

**Match the dominant signal.** A generated component must look like the team's other components.

## Greenfield default — CSS Modules + CSS custom properties

Zero-config with Vite, scoped by default, no dependency:

```tsx
import styles from './Button.module.css'

export function Button({ variant = 'primary', ...props }: ButtonProps) {
  return <button className={`${styles.btn} ${styles[variant]}`} {...props} />
}
```

```css
/* Button.module.css */
.btn { padding: var(--space-2) var(--space-4); border-radius: var(--radius); font: inherit; cursor: pointer; }
.primary { background: var(--color-primary); color: var(--color-on-primary); }
.ghost { background: transparent; color: var(--color-primary); }
```

```css
/* styles/theme.css — design tokens; the single theming surface */
:root {
  --color-primary: #2563eb; --color-on-primary: #fff;
  --space-2: 0.5rem; --space-4: 1rem; --radius: 0.375rem;
}
:root[data-theme='dark'] { --color-primary: #3b82f6; }
```

## Conventions

- **Match, don't impose.** The base never forces Tailwind or a UI library; opinionated systems are addons (`bench-tailwind`, `bench-shadcn`, `bench-mui`, `bench-chakra`, `bench-radix`).
- **Theme via CSS custom properties** (greenfield). One token file is the theming surface; dark mode = a `[data-theme]` / `prefers-color-scheme` override.
- **No inline `style={{}}`** except genuinely dynamic computed values. Static styling goes in classes.

## Don't

- Don't introduce a styling dependency the project doesn't use — recommend the matching addon.
- Don't hard-code colors/spacing — use tokens (CSS vars, or the project's Tailwind/theme config).

## See also

- [COMPONENT-001](../components/COMPONENT-001-conventions.md) · addons: `bench-tailwind`, `bench-shadcn`, `bench-mui`, `bench-chakra`
