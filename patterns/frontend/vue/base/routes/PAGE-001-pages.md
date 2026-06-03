# PAGE-001-pages

## Pattern

Page components are the route-level entry points. They live in `src/modules/{Name}/pages/` and have the `*Page.vue` suffix. Pages compose smaller components, fetch data via services, and orchestrate user interactions.

## Structure

```vue
<script lang="ts" setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { task } from 'src/composables/task';   // project's async-task helper — discover convention
import TaskErrors from 'src/components/TaskErrors.vue';
import BillCard from '../components/Cards/BillCard.vue';
import BillFormDialog from '../components/Dialogs/BillFormDialog.vue';
import { BillService } from '../services/BillService';
import { BillRoutes } from '../router/constants';
import type { Bill } from '../types/bill.types';

const router = useRouter();
const { t } = useI18n();

const bills = ref<Bill[]>([]);
const showFormDialog = ref(false);

const loadTask = task({
  task: async () => {
    bills.value = await BillService.list();
  },
  showNotification: {
    error: () => t('bill.notifications.errors.loadFailed'),
  },
});

function openCreateDialog() {
  showFormDialog.value = true;
}

function handleDialogSuccess(bill: Bill) {
  bills.value.unshift(bill);
}

function handleCardClick(bill: Bill) {
  void router.push({ name: BillRoutes.DETAIL, params: { id: bill.id } });
}

onMounted(() => {
  void loadTask.run();
});
</script>

<template>
  <div class="bill-list-page p-4 md:p-8">
    <header class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">{{ $t('bill.pages.list.title') }}</h1>
        <p class="text-gray-600">{{ $t('bill.pages.list.subtitle') }}</p>
      </div>
      <button @click="openCreateDialog">+</button>
    </header>

    <TaskErrors :task-errors="loadTask.errors.value" class="mb-4" />

    <!-- Loading skeleton -->
    <div v-if="loadTask.isActive.value" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="n in 3" :key="n" class="skeleton" />
    </div>

    <!-- Empty state -->
    <div v-else-if="bills.length === 0" class="empty p-8 text-center">
      <p>{{ $t('bill.pages.list.empty.title') }}</p>
    </div>

    <!-- Data -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <BillCard
        v-for="bill in bills"
        :key="bill.id"
        :bill="bill"
        @click="handleCardClick(bill)"
      />
    </div>

    <BillFormDialog
      v-model="showFormDialog"
      mode="create"
      @success="handleDialogSuccess"
    />
  </div>
</template>
```

If the project uses a UI library, substitute its primitives (buttons, skeletons, cards). Follow what sibling pages do.

## Page Lifecycle

1. **Mount** — fetch initial data via the project's task helper
2. **Loading state** — show skeletons (`task.isActive.value`)
3. **Error state** — show task errors and/or empty state
4. **Data state** — render the list/detail
5. **Mutations** — open dialogs, call services via the task helper, refresh local state on success

## Conventions

- Suffix: `*Page.vue` (`BillsPage.vue`, `BillPage.vue`, `HouseholdMembersPage.vue`)
- Page is the orchestrator — owns state for the route
- Use the project's service-access convention (plain import, DI helper, etc.)
- Use the project's async-task helper for ALL async work — discover from siblings
- Use `useRouter()` for navigation, `useRoute()` for params
- Use `onMounted(() => void loadTask.run())` for initial fetch (the `void` discards the promise)
- Use route name constants for navigation (never hardcoded strings)
- i18n via `$t(...)` in template, `t(...)` from `useI18n()` in script

## Loading + Empty + Error States

Every page that fetches data should explicitly handle:
- **Loading** (`v-if="task.isActive.value"`) — skeleton
- **Empty** (`v-else-if="data.length === 0"`) — empty state with CTA
- **Data** (`v-else`) — render list/items
- **Error** — the project's error-display component bound to `task.errors.value`

## Page Sizing

- Pages > 400 lines → extract sections into `components/Sections/`
- Repeated logic across pages → extract to composable

## Key Points

- One Page per route, suffixed `*Page.vue`
- Pages own state and orchestrate; components present
- Use the project's async-task helper for all async work
- Always handle loading + empty + error states explicitly
- Navigate via route name constants from `router/constants.ts`
- See ROUTE-001 for route definitions, ROUTE-002 for route name constants
