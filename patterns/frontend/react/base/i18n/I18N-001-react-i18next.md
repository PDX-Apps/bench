# i18n — react-i18next (optional)

Internationalization with **react-i18next**. Common but **not universal** — only apply when the project has it installed. A generated component must not hard-require i18n if the project doesn't use it (plain strings then, and recommend adopting it).

## Use — `useTranslation()`

```tsx
import { useTranslation } from 'react-i18next'

export function UsersHeader({ total }: { total: number }) {
  const { t } = useTranslation()
  return (
    <header>
      <h1>{t('users.title')}</h1>
      <p>{t('users.count', { count: total })}</p>
    </header>
  )
}
```

```json
// locales/en/translation.json
{ "users": { "title": "Users", "count_one": "{{count}} user", "count_other": "{{count}} users" } }
```

## Conventions

- **`useTranslation()`** hook; namespaced hierarchical keys (`users.title`). One namespace per feature.
- **Interpolation `{{var}}`** and i18next plurals (`_one`/`_other` with `count`) — no string concatenation.
- **Locale files per language**; keep keys identical across locales.
- **Typed keys** if the project configures i18next's typed resources — match it.

## Don't

- Don't hard-require i18n in a project that doesn't use it — plain strings + suggest react-i18next.
- Don't concatenate display strings; use interpolation/plurals.

## See also

- [COMPONENT-001](../components/COMPONENT-001-conventions.md)
