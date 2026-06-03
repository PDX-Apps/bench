# COMPONENT-003-dialogs

## Pattern

Dialog components live in `components/Dialogs/`. They wrap a modal element, manage open/close state via `defineModel`, contain a Form (see COMPONENT-002), and call services to persist data.

## Structure

```vue
<script lang="ts" setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { task } from 'src/composables/task';   // project's async-task helper — discover convention
import { BillService } from '../../services/BillService';
import BillForm, { type BillFormData } from '../BillForm.vue';
import type { Bill } from '../../types/bill.types';

/**
 * Props
 */
interface Props {
  mode: 'create' | 'edit';
  bill?: Bill | undefined;
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'create',
});

/**
 * Model — open/close state
 */
const model = defineModel<boolean>({ required: true });

/**
 * Emits
 */
const emit = defineEmits<{
  success: [bill: Bill];
}>();

/**
 * Composables
 */
const { t } = useI18n();

/**
 * State
 */
const formData = ref<BillFormData>({
  name: props.bill?.name ?? '',
  amount: props.bill?.amount ?? 0,
  // ... map from props.bill or defaults
});

/**
 * Computed
 */
const dialogTitle = computed(() =>
  props.mode === 'create'
    ? t('bill.dialog.createTitle')
    : t('bill.dialog.editTitle'),
);

/**
 * Tasks
 */
const submitTask = task({
  task: async () => {
    return props.mode === 'create'
      ? BillService.create(formData.value)
      : BillService.update(props.bill!.id, formData.value);
  },
  showNotification: {
    success: () => t('bill.notifications.success.saved'),
    error: () => t('bill.notifications.errors.saveFailed'),
  },
});

/**
 * Methods
 */
async function handleSubmit() {
  const bill = await submitTask.run();
  if (bill) {
    emit('success', bill);
    model.value = false;  // close dialog
  }
}
</script>

<template>
  <!--
    Use whatever modal component the project provides:
    plain <dialog>, Quasar <q-dialog>, Vuetify <v-dialog>, headless UI Dialog, etc.
    Discover the convention from sibling dialogs.
  -->
  <dialog :open="model" class="dialog">
    <article class="dialog-content">
      <header><h2>{{ dialogTitle }}</h2></header>

      <section>
        <BillForm v-model="formData" @valid-submit="handleSubmit" />
        <TaskErrors :task-errors="submitTask.errors.value" class="mt-4" />
      </section>

      <footer>
        <button @click="model = false">{{ t('common.cancel') }}</button>
        <button
          :disabled="submitTask.isActive.value"
          @click="handleSubmit"
        >
          {{ t('common.save') }}
        </button>
      </footer>
    </article>
  </dialog>
</template>
```

## Open/Close Pattern

Use `defineModel<boolean>({ required: true })` for the v-model bound to dialog visibility. Parent controls visibility:

```vue
<!-- Parent -->
<button @click="showDialog = true">Add Bill</button>
<BillFormDialog v-model="showDialog" mode="create" @success="handleSuccess" />
```

## Mode Pattern

Dialogs that handle both create AND edit use a `mode: 'create' | 'edit'` prop:
- `'create'` — empty form, calls `service.create(...)`
- `'edit'` — pre-filled form (from the model passed in `bill?` prop), calls `service.update(...)`

Title and button labels switch on `mode`.

## Persistent vs Dismissable

- Persistent (user must click cancel/save) — preferred for forms
- Dismissable (clicking outside closes) — preferred for read-only displays

How this is configured depends on the UI library — follow project convention.

## Conventions

- One dialog per concern (don't combine create/edit/delete in one)
- Always emit `success` (or similar) so parent can refresh data
- Close the dialog yourself (`model.value = false`) on success — don't rely on parent
- Show loading state on the submit button via `task.isActive.value` (project's async-task helper)
- Show task errors with the project's error-display component

## Key Points

- Dialogs wrap the project's modal primitive with `defineModel<boolean>` for visibility
- They contain a Form (COMPONENT-002) and handle the service call themselves
- Use the project's async-task helper for submission (built-in loading + error handling)
- `mode` prop for create-vs-edit reuse
- Always emit a success event for parent data refresh
- Always close the dialog on success
