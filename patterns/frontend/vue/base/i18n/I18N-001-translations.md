# I18N-001-translations

## Pattern

Each module owns its translations under `i18n/{locale}/`. Translations are structured as nested TypeScript objects, namespaced by module, with hierarchical keys.

## File Structure

```
src/modules/Bill/i18n/
├── en-US/
│   ├── index.ts          # Aggregates module translations
│   └── bill.ts           # The translation tree (namespace = bill)
└── es-MX/
    ├── index.ts
    └── bill.ts
```

Locales are discovered from the project — list the existing `i18n/` subdirectories in any module to find what's configured. Don't assume specific locales.

## Aggregation File

`{locale}/index.ts` re-exports all namespace files for the module:

```typescript
import bill from './bill';

export default {
  bill,            // accessible as `bill.{key}`
  // notification, // additional namespaces if the module has more
};
```

## Translation File

```typescript
// src/modules/Bill/i18n/en-US/bill.ts
export default {
  pages: {
    list: {
      title: 'My Bills',
      subtitle: 'Track and manage your bills',
      empty: {
        title: 'No Bills Yet',
        description: 'Create your first bill to start tracking expenses',
      },
    },
    detail: {
      title: 'Bill Details',
      members: 'Members',
    },
  },
  card: {
    dueDate: 'Due',
    amount: 'Amount',
    autoPay: 'Auto-pay',
  },
  form: {
    name: 'Bill Name',
    namePlaceholder: 'e.g. Electricity',
    amount: 'Amount',
    dueDate: 'Due Date',
  },
  actions: {
    create: 'Create Bill',
    edit: 'Edit',
    delete: 'Delete',
  },
  notifications: {
    success: {
      created: 'Bill created successfully',
      updated: 'Bill updated successfully',
    },
    errors: {
      loadFailed: 'Failed to load bills',
      createFailed: 'Failed to create bill',
    },
  },
};
```

## Module Registration

How translations get merged into vue-i18n depends on the project's setup. Read an existing module's `index.ts` to discover the convention. A typical generic shape:

```typescript
import enUSTranslations from './i18n/en-US';
import esMXTranslations from './i18n/es-MX';

// Either the project merges these into a vue-i18n root config, or a framework
// wrapper registers them via a Module object.
export const messages = {
  'en-US': enUSTranslations,
  'es-MX': esMXTranslations,
};
```

## Key Naming Conventions

Hierarchical, lowercase, namespace-first:

```
{module}.{section}.{key}
{module}.{section}.{subsection}.{key}
```

Examples:
- `bill.pages.list.title`
- `bill.pages.list.empty.description`
- `bill.actions.create`
- `bill.notifications.success.created`

Standard top-level sections within a namespace:

| Section | Purpose |
|---------|---------|
| `pages` | Page-level text (titles, subtitles, empty states) |
| `card` | Card component text |
| `form` | Form labels, placeholders, hints |
| `dialog` | Dialog titles, button labels |
| `actions` | Button labels (create, edit, delete, save, cancel) |
| `breadcrumb` | Breadcrumb labels (used in route meta) |
| `notifications` | Notification messages, split by `success`/`errors`/`warnings` |
| `status` | Status messages (often referenced from enums — see ENUM-001) |
| `frequency`, `type`, etc. | Per-domain enums |

## Usage in Components

```vue
<template>
  <!-- Template: $t() -->
  <h1>{{ $t('bill.pages.list.title') }}</h1>
</template>

<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
t('bill.actions.create');
</script>
```

If the project's framework wrapper exposes its own i18n helper, follow that convention.

## Pluralization

vue-i18n supports plural forms with `|` separator:

```typescript
// translations
billCount: 'no bills | one bill | {count} bills',
```

```typescript
// usage
t('bill.billCount', billCount, { count: billCount });
```

## Interpolation

Named placeholders:

```typescript
welcome: 'Welcome, {name}!',
```

```typescript
t('user.welcome', { name: user.name });
```

## Adding a New Locale

1. Create `src/modules/{Module}/i18n/{locale}/index.ts` and translation files
2. Register in the project's i18n setup (root vue-i18n config or framework wrapper)
3. Mirror in every module that has i18n

## Anti-Patterns

```typescript
// ❌ Hardcoded text in components
<h1>My Bills</h1>

// ❌ Flat keys
'billListTitle': 'My Bills'

// ❌ Translations outside module ownership
// (don't put bill translations in a shared Core/i18n)

// ❌ Per-component i18n files
// (one tree per module is the convention)
```

## Key Points

- Each module owns its translations under `i18n/{locale}/`
- `{locale}/index.ts` aggregates the namespace files
- Hierarchical nested object: `module.section.key`
- Namespace = top-level key in the translation tree (matches enum prefix `module::`)
- Standard sections: `pages`, `card`, `form`, `dialog`, `actions`, `breadcrumb`, `notifications`, `status`
- Use `$t()` in templates, `t()` from `useI18n()` in scripts
- Configured locales are project-defined — discover from existing modules
- See ENUM-001 for status enums whose values are i18n keys
