# I18N-001-translations

## Pattern

React projects typically use **react-i18next** for translations. Each module owns its translations under `i18n/{locale}/`, structured as nested JS objects, namespaced by module, with hierarchical keys.

If the project uses a different library (lingui, formatjs, polyglot), follow that convention.

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

Discover the project's configured locales from any existing module's `i18n/` directory.

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
  status: {
    unpaid: 'Unpaid',
    paid: 'Paid',
    partial: 'Partially Paid',
    skipped: 'Skipped',
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

## Aggregation File

`{locale}/index.ts` re-exports all namespaces for the module:

```typescript
import bill from './bill';

export default {
  bill,            // accessible as `bill.{key}`
};
```

## Project-Level Registration

How translations get merged into i18next depends on the project's setup. Read an existing module's registration. A common shape:

```typescript
// src/i18n/index.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import enUSBill from 'src/modules/Bill/i18n/en-US';
import esMXBill from 'src/modules/Bill/i18n/es-MX';
// ...

const resources = {
  'en-US': { translation: { ...enUSBill /*, ...other modules */ } },
  'es-MX': { translation: { ...esMXBill /*, ...other modules */ } },
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'en-US',
  fallbackLng: 'en-US',
  interpolation: { escapeValue: false },
});

export default i18n;
```

## Usage in Components

```tsx
import { useTranslation } from 'react-i18next';

function BillCard({ bill }: { bill: Bill }) {
  const { t } = useTranslation();
  return (
    <article>
      <h3>{t('bill.card.amount')}: {bill.amount}</h3>
      <p>{t('bill.actions.edit')}</p>
    </article>
  );
}
```

For non-React contexts (utilities, store actions), import the i18n instance:

```typescript
import i18n from 'src/i18n';
const message = i18n.t('bill.notifications.errors.loadFailed');
```

## Key Naming Conventions

Hierarchical, lowercase, namespace-first:

```
{module}.{section}.{key}
{module}.{section}.{subsection}.{key}
```

Examples:
- `bill.pages.list.title`
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
| `breadcrumb` | Breadcrumb labels |
| `notifications` | Notification messages, split by `success`/`errors`/`warnings` |
| `status` | Status messages (often referenced from enums — see ENUM-001) |

## Interpolation + Plurals

```typescript
// translations
welcome: 'Welcome, {{name}}!',
billCount_one: '{{count}} bill',
billCount_other: '{{count}} bills',
```

```typescript
// usage
t('user.welcome', { name: user.name });
t('bill.billCount', { count: bills.length });   // auto-selects _one vs _other
```

## Adding a New Locale

1. Create `src/modules/{Module}/i18n/{locale}/` with translation files
2. Mirror in every module that has i18n
3. Update the i18n init config to include the new resources

## Anti-Patterns

```tsx
// ❌ Hardcoded text in components
<h1>My Bills</h1>

// ❌ Flat keys
'billListTitle': 'My Bills'

// ❌ Translations outside module ownership
// (don't put bill translations in src/common/i18n)
```

## Key Points

- Each module owns its translations under `i18n/{locale}/`
- `{locale}/index.ts` aggregates the namespace files
- Hierarchical nested object: `module.section.key`
- Use `useTranslation()` in components, `i18n.t()` outside React
- Discover configured locales from the project; don't hardcode
- See ENUM-001 for status enums whose values are i18n keys
