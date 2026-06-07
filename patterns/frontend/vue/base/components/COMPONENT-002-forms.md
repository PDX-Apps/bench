# Vue Component — forms

Form components: bind fields, validate with [Zod](../validation/VALIDATOR-001-zod.md), emit a typed payload on valid submit. The base stays library-light (plain refs + Zod); if the project uses **vee-validate** or a UI library's form system, match that instead.

## When

Any create/edit form. Pair with a Zod schema ([VALIDATOR-001](../validation/VALIDATOR-001-zod.md)) and, for persistence, a mutation ([QUERY-001](../data/QUERY-001-tanstack-query.md)).

## Shape — refs + Zod, emit on valid submit

```vue
<script setup lang="ts">
import { reactive, ref } from 'vue'
import { userFormSchema, type UserFormValues } from '@/validation/user'

const props = defineProps<{ initial?: Partial<UserFormValues>; submitting?: boolean }>()
const emit = defineEmits<{ submit: [values: UserFormValues] }>()

const form = reactive<UserFormValues>({
  firstName: props.initial?.firstName ?? '',
  email: props.initial?.email ?? '',
})
const errors = ref<Partial<Record<keyof UserFormValues, string>>>({})

function onSubmit() {
  const result = userFormSchema.safeParse(form)
  if (!result.success) {
    errors.value = Object.fromEntries(
      result.error.issues.map((i) => [i.path[0], i.message]),
    )
    return
  }
  errors.value = {}
  emit('submit', result.data)
}
</script>

<template>
  <form novalidate @submit.prevent="onSubmit">
    <label>
      First name
      <input v-model="form.firstName" name="firstName" :aria-invalid="!!errors.firstName" />
      <span v-if="errors.firstName" role="alert">{{ errors.firstName }}</span>
    </label>

    <label>
      Email
      <input v-model="form.email" name="email" type="email" :aria-invalid="!!errors.email" />
      <span v-if="errors.email" role="alert">{{ errors.email }}</span>
    </label>

    <button type="submit" :disabled="submitting">Save</button>
  </form>
</template>
```

## Conventions

- **Validate with the Zod schema** (`safeParse`) — one schema is the source of truth for both the form and the API payload type (`z.infer`). See [VALIDATOR-001](../validation/VALIDATOR-001-zod.md).
- **The form component doesn't persist** — it emits the validated payload; the parent (a page or a mutation composable) calls the API. Keeps the form reusable for create *and* edit.
- **`submitting` prop** disables the button during the parent's async submit; don't manage server state inside the form.
- **Accessibility**: `<label>` wrapping each input (or `for`/`id`), `aria-invalid`, `role="alert"` on messages, `novalidate` + `@submit.prevent`.

## Don't

- Don't duplicate validation rules in the template — derive everything from the Zod schema.
- Don't fetch or mutate inside the form component.
- Don't reach for a form library unless the project already uses one (then match it).

## See also

- [VALIDATOR-001](../validation/VALIDATOR-001-zod.md) · [QUERY-001](../data/QUERY-001-tanstack-query.md) · [COMPONENT-001](./COMPONENT-001-conventions.md)
