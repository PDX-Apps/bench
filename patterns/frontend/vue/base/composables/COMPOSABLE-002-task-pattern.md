# COMPOSABLE-002-task-pattern

## Pattern

Async work in components needs a consistent shape: reactive loading state, captured errors, optional success/error notifications, and reset between calls. Re-implementing this every time is tedious and bug-prone — extract it into a `task()` composable (or use the project's existing equivalent).

## Why a task composable (not raw async/await)

Raw async/await leaves you re-implementing in every component:

- Loading state (`isLoading.value = true; ... isLoading.value = false`)
- Error capture (`try/catch` + error refs)
- Success/error notifications
- Reset state between calls

A `task()` composable provides all four out of the box, reactively. Many Vue projects provide one — either through a framework wrapper, VueUse's `useAsyncState`, or a custom helper. Use whichever the project provides. If none exists, this pattern shows the shape to build.

## Discover the Project's Helper

Before writing async code, check:

```bash
grep -rh "task\|useAsyncState\|useFetch" src/composables/ 2>/dev/null | head
grep -rh "from '.*task" src/modules/*/composables/ 2>/dev/null | head
```

If the project has a `task()` or equivalent, follow its API. If not, fall back to the inline pattern below.

## Generic shape (project-provided `task()`)

```typescript
import { task } from 'src/composables/task';   // or wherever the project keeps it
import { BillService } from 'src/modules/Bill/services/BillService';

const loadTask = task({
  task: async () => {
    bills.value = await BillService.list();
  },
  showNotification: {
    success: () => i18n.t('bill.notifications.success.loaded'),
    error: () => i18n.t('bill.notifications.errors.loadFailed'),
  },
});

onMounted(() => void loadTask.run());
```

## Reactive Properties

A `task()` helper typically exposes:

| Property | Type | Description |
|----------|------|-------------|
| `isActive` | `Ref<boolean>` | True while the task is running |
| `errors` | `Ref<TaskError[]>` | Array of errors from the most recent run |
| `data` | `Ref<T>` | The task's resolved value (if it returns one) |

Use them in templates:

```vue
<button :disabled="loadTask.isActive.value" @click="loadTask.run()">Load</button>
<TaskErrors :task-errors="loadTask.errors.value" />
```

## Methods

| Method | Description |
|--------|-------------|
| `run(...args)` | Execute the task. Returns a Promise that resolves to the task's return value. |
| `reset()` | Clear errors and data, set `isActive` to false. |

## Inline fallback — when the project has no helper

If no shared `task()` exists, reimplement the four ingredients inline (and consider extracting one):

```typescript
import { ref } from 'vue';

const bills = ref<Bill[]>([]);
const isLoading = ref(false);
const error = ref<unknown>(null);

async function loadBills() {
  isLoading.value = true;
  error.value = null;
  try {
    bills.value = await BillService.list();
  } catch (e) {
    error.value = e;
  } finally {
    isLoading.value = false;
  }
}
```

## Combining with Form Submit

Standard pattern in Dialogs:

```typescript
const submitTask = task({
  task: async () => BillService.create(formData.value),
  showNotification: {
    success: () => i18n.t('bill.notifications.success.created'),
    error: () => i18n.t('bill.notifications.errors.createFailed'),
  },
});

async function handleSubmit() {
  const bill = await submitTask.run();
  if (bill) {
    emit('success', bill);
    model.value = false;  // close dialog
  }
}
```

## Anti-Patterns

```typescript
// ❌ Different ad-hoc loading-state shapes in every component
let loading = false;
try { ... } catch (e) { someOtherErrorRef.value = e; }

// ✅ Use the project's task() composable (or extract one if missing)
const t = task({ task: ..., showNotification: { ... } });
await t.run();
```

```typescript
// ❌ Forgetting to await run()
loadTask.run();  // promise floats

// ✅ Either await it or `void` discard explicitly
await loadTask.run();
void loadTask.run();  // OK in onMounted
```

## Key Points

- Use the project's existing async-task helper if there is one (VueUse provides `useAsyncState`)
- The four ingredients to capture: `isActive`, `errors`, `data`, `run()`
- Pair `isActive` with button `:disabled` / skeleton loaders
- Pair `errors` with a generic error-display component
- Returning a value from the task makes it accessible to consumers
- See COMPONENT-002 for forms, COMPONENT-003 for dialogs
