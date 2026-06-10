---
mode: append
---

## Quasar theming (this project uses quasar)

Theme through Quasar's **brand colors** and utility classes, not ad-hoc CSS.

### Brand colors

Set the palette once in `quasar.variables.sass` / `src/css/quasar.variables.sass` (`$primary`, `$secondary`, `$accent`, `$dark`, `$positive`, `$negative`, `$info`, `$warning`) — or at runtime via `setCssVar('primary', '#2563eb')`. Reference them through the `color`/`text-color`/`bg-color` props and the `text-*` / `bg-*` helper classes; never hard-code hex:

```vue
<q-btn color="primary" />
<q-banner class="bg-warning text-white" />
<div class="text-primary">…</div>
```

Semantic colors (`positive`/`negative`/`warning`/`info`) carry meaning — use them for status, not arbitrary palette colors.

### Dark mode

Drive it through the **Dark plugin**, not manual class toggling:

```ts
import { useQuasar } from "quasar"
const $q = useQuasar()
$q.dark.set(true)        // or false, or "auto" (follow the OS)
$q.dark.toggle()
const isDark = $q.dark.isActive
```

Quasar components adapt automatically; the `q-dark` / `body--dark` classes let your own styles follow.

### Spacing & layout utilities

Use Quasar's classes before writing CSS:

- **Spacing**: `q-pa-md` (padding all, medium), `q-mt-sm`, `q-mx-lg`, `q-gutter-md` (gaps between children).
- **Flexbox**: `row`/`column`, `items-center`, `justify-between`, `col`/`col-6` (12-col grid).
- **Typography**: `text-h6`, `text-caption`, `text-weight-medium`.

### Don't

- Don't hard-code hex — use brand colors / `setCssVar` and the `text-*`/`bg-*` helpers.
- Don't toggle dark mode by hand — use the `$q.dark` API.
- Don't write CSS for spacing/flex/typography that a Quasar utility class already covers.
