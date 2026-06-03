# COMPONENT-002-forms

## Pattern

Form components live in `components/Forms/`. They emit form data to a parent (often a Dialog — see COMPONENT-003). Per-field validation uses Zod schemas; form-level submission uses the project's async-task helper (see COMPOSABLE-002).

## Structure

```vue
<script lang="ts" setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { nameSchema, emailSchema } from '../../validators/userValidators';

/**
 * Form data shape (exported for parent consumption)
 */
export interface UserFormData {
  name: string;
  email: string;
  notes: string;
}

/**
 * Props
 */
interface Props {
  initial?: Partial<UserFormData>;
}

const props = withDefaults(defineProps<Props>(), {
  initial: () => ({}),
});

/**
 * Model — bidirectional binding with parent
 */
const formData = defineModel<UserFormData>({ required: true });

/**
 * Emits
 */
const emit = defineEmits<{
  validSubmit: [data: UserFormData];
}>();

/**
 * Composables
 */
const { t } = useI18n();

/**
 * State (only if needed beyond model)
 */
const submitted = ref(false);
</script>

<template>
  <form @submit.prevent="emit('validSubmit', formData)">
    <BaseInput
      v-model="formData.name"
      :label="t('user.form.name')"
      :schema="nameSchema()"
      required
    />
    <BaseInput
      v-model="formData.email"
      :label="t('user.form.email')"
      :schema="emailSchema()"
      type="email"
      required
    />
    <label>
      {{ t('user.form.notes') }}
      <textarea v-model="formData.notes" />
    </label>
    <button type="submit">{{ t('user.actions.save') }}</button>
  </form>
</template>
```

If the project uses a UI library (Quasar, Vuetify, etc.), substitute its form components — follow what sibling forms do.

## Input wrapper + Zod

`BaseInput` (or whatever the project calls its input wrapper) is typically a thin wrapper around the UI library's input that integrates with Zod schemas:

```vue
<BaseInput v-model="email" :schema="emailSchema()" />
```

`emailSchema()` returns a fresh Zod schema (factory function — see VALIDATOR-001). The wrapper runs the schema on input/blur and shows validation errors inline. If the project doesn't have such a wrapper, validate manually inside the form's submit handler.

## Submission via the project's task helper

Forms typically delegate submission to their parent (Dialog or Page). The submitting component wraps the call in the project's async-task helper (see COMPOSABLE-002):

```typescript
const submitTask = task({
  task: async () => BillService.create(formData.value),
  showNotification: {
    success: () => t('bill.notifications.success.created'),
    error: () => t('bill.notifications.errors.createFailed'),
  },
});

async function handleValidSubmit(data: BillFormData) {
  const bill = await submitTask.run();
  if (bill) emit('success', bill);
}
```

Use `submitTask.isActive.value` to disable the submit button and show loading state.

## Form Errors

Display task-level errors with the project's error-display component (e.g., `TaskErrors`):

```vue
<TaskErrors :task-errors="submitTask.errors.value" />
```

Per-field errors come automatically from the input wrapper + Zod (if the wrapper supports it). Otherwise show inline.

## Conventions

- Forms emit `validSubmit` (or similar) with form data — they don't call services directly
- Parent wraps the call in the project's task helper for loading/error/notification handling
- Export the `*FormData` interface for parent type-safety
- Use `defineModel` for bidirectional binding (parent passes initial data + receives changes)
- Use the project's input wrapper for fields that need Zod validation
- Use plain UI library inputs for fields without complex validation

## Key Points

- Forms are "dumb" — they collect data and emit; they don't call services
- Validation = Zod schemas via the project's input wrapper (per-field) + task errors (form-level)
- Submission = parent's task helper wrapping the service call
- Use `defineModel` for two-way data binding
- Export `*FormData` interface from the form component for parent typing
- See VALIDATOR-001 for Zod schema patterns
- See COMPOSABLE-002 for the async-task pattern
