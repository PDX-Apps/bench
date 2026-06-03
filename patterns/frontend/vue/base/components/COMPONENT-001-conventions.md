# COMPONENT-001-conventions

## Pattern

Vue 3 SFCs (Single File Components) using `<script lang="ts" setup>`. Components live under `src/modules/{Name}/components/` (or whatever feature-folder convention the project uses) organized by semantic folders.

## Folder Conventions

| Folder | Purpose | Example |
|--------|---------|---------|
| `Cards/` | Display a single resource summary | `BillCard.vue` |
| `Dialogs/` | Modal dialogs (create/edit, confirm) | `BillFormDialog.vue` |
| `Forms/` | Form components (often used inside Dialogs) | `BillForm.vue` |
| `Inputs/` | Reusable input wrappers | `EmailInput.vue` |
| `Sections/` | Page sections (HeroSection, FeatureSection) | `HeroSection.vue` |
| `Common/` | Cross-cutting utilities (TaskErrors, EmptyState) | `TaskErrors.vue` |
| `Layouts/` | (in `layouts/` not `components/`) | See LAYOUT-001 |

Components that don't fit a folder live at the module's `components/` root.

## Structure

```vue
<script lang="ts" setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import type { Bill } from '../../types/bill.types';

/**
 * Props
 */
interface Props {
  bill: Bill;
  expandable?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  expandable: false,
});

/**
 * Emits
 */
const emit = defineEmits<{
  click: [bill: Bill];
  edit: [bill: Bill];
}>();

/**
 * Composables
 */
const { t } = useI18n();

/**
 * State
 */
const expanded = ref(false);

/**
 * Computed
 */
const formattedAmount = computed(() => /* ... */);

/**
 * Methods
 */
function handleClick() {
  emit('click', props.bill);
}
</script>

<template>
  <article class="bill-card" @click="handleClick">
    <h3 class="text-lg font-semibold">{{ bill.name }}</h3>
    <p class="text-sm">{{ formattedAmount }}</p>
  </article>
</template>
```

If the project uses a UI library (Quasar, Vuetify, etc.), substitute its primitives (`<q-card>`, `<v-card>`) for the plain markup above — follow what sibling components do.

## Conventions

- **`<script lang="ts" setup>`** — always TypeScript, always `setup`
- **Section comments** — `/** Props */`, `/** Emits */`, `/** Composables */`, `/** State */`, `/** Computed */`, `/** Methods */` headers in this order
- **Named interfaces** for props (`interface Props { ... }`)
- **`withDefaults(defineProps<Props>(), { ... })`** for default values
- **Tuple-typed emits** with `defineEmits<{ name: [arg: T] }>()`
- **`defineModel`** for v-model (instead of value/input pattern)
- **Service access** via the project's convention (plain import, DI helper, framework wrapper) — see SERVICE-002
- **i18n keys** via `$t('module.section.key')` in template OR `t(...)` from `useI18n()` in script
- **UI library** — discover from existing components; don't introduce a new one

## Sizing Guidance

- Components > 300 lines → split into sub-components
- Repeated logic in 3+ components → extract to composable (see COMPOSABLE-001)
- Pure presentation components: no services — just props in, events out
- "Smart" components (data-fetching, mutations): use the project's async-task helper (see COMPOSABLE-002) and services

## Naming

- PascalCase filenames (`BillCard.vue`, `MemberSplitInput.vue`)
- Match the file's primary purpose: `BillCard` shows a Bill, `BillForm` edits one, `BillFormDialog` wraps the form in a dialog
- For variants, suffix with the variant: `BillForm.vue` and `HouseholdBillForm.vue`

## Key Points

- One component per file, named to match the filename
- Section comments organize the script in a consistent order
- Props/emits typed with TS, defaults via `withDefaults`
- Use the project's existing conventions for services, async work, UI library
- Components in semantic folders (Cards/Dialogs/Forms/Inputs/Sections)
- See COMPONENT-002 for forms, COMPONENT-003 for dialogs
