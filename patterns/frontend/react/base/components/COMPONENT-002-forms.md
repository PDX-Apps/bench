# React Component — forms

Forms with **react-hook-form** + **Zod** (via `@hookform/resolvers/zod`) — the standard modern React combo. The Zod schema is the single source of truth for validation + the form type.

## Shape

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { userFormSchema, type UserFormValues } from '@/validation/user'

interface UserFormProps {
  defaultValues?: Partial<UserFormValues>
  submitting?: boolean
  onSubmit: (values: UserFormValues) => void
}

export function UserForm({ defaultValues, submitting, onSubmit }: UserFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<UserFormValues>({
    resolver: zodResolver(userFormSchema),
    defaultValues,
  })

  return (
    <form noValidate onSubmit={handleSubmit(onSubmit)}>
      <label>
        First name
        <input {...register('firstName')} aria-invalid={!!errors.firstName} />
        {errors.firstName && <span role="alert">{errors.firstName.message}</span>}
      </label>

      <label>
        Email
        <input type="email" {...register('email')} aria-invalid={!!errors.email} />
        {errors.email && <span role="alert">{errors.email.message}</span>}
      </label>

      <button type="submit" disabled={submitting}>Save</button>
    </form>
  )
}
```

## Conventions

- **`useForm<T>` + `zodResolver(schema)`** — validation rules come from the Zod schema, never restated in the component.
- **`{...register('field')}`** for inputs; `handleSubmit(onSubmit)` runs validation then calls your handler with typed values. Use `Controller` only for controlled/3rd-party inputs.
- **The form doesn't persist** — `onSubmit` emits the validated payload; the parent (page or mutation hook) calls the API. Keeps it reusable for create *and* edit.
- **`submitting` prop** disables the button during the parent's async submit.
- **Accessibility**: `<label>`, `aria-invalid`, `role="alert"` on messages, `noValidate`.

## Don't

- Don't duplicate validation in the component — derive from the Zod schema.
- Don't fetch or mutate inside the form.
- Don't reach for another form lib if the project already uses react-hook-form (or match the project's if different).
