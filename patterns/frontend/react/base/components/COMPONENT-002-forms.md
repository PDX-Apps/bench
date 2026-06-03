# COMPONENT-002-forms

## Pattern

Form components live in `components/Forms/`. Use **react-hook-form** + **Zod resolver** for validation (the de-facto standard). Form components emit data via callbacks; the parent handles submission via the project's async-task helper.

## Structure

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';
import { z } from 'zod';
import { nameSchema, emailSchema } from '../../validators/userValidators';

export interface UserFormData {
  name: string;
  email: string;
  notes: string;
}

const userFormSchema = z.object({
  name: nameSchema(),
  email: emailSchema(),
  notes: z.string().optional(),
});

interface UserFormProps {
  defaultValues?: Partial<UserFormData>;
  onValidSubmit: (data: UserFormData) => void;
}

export function UserForm({ defaultValues, onValidSubmit }: UserFormProps) {
  const { t } = useTranslation();
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<UserFormData>({
    resolver: zodResolver(userFormSchema),
    defaultValues,
  });

  return (
    <form onSubmit={handleSubmit(onValidSubmit)} data-testid="user-form">
      <label>
        {t('user.form.name')}
        <input {...register('name')} data-testid="user-form-name" />
        {errors.name && <span className="error">{errors.name.message}</span>}
      </label>

      <label>
        {t('user.form.email')}
        <input type="email" {...register('email')} data-testid="user-form-email" />
        {errors.email && <span className="error">{errors.email.message}</span>}
      </label>

      <label>
        {t('user.form.notes')}
        <textarea {...register('notes')} />
      </label>

      <button type="submit" disabled={isSubmitting}>
        {t('user.actions.save')}
      </button>
    </form>
  );
}
```

If the project uses a different form library (Formik, native React state, TanStack Form), follow that convention.

## Per-field validation

Compose primitive Zod schemas (see VALIDATOR-001) into the form-level schema:

```typescript
import { z } from 'zod';
import { emailSchema, passwordSchema } from '../../validators/authValidators';

const loginFormSchema = z.object({
  email: emailSchema(),
  password: passwordSchema(),
});
```

`zodResolver` runs the schema on submit (and on change/blur per `mode` config). `formState.errors` exposes per-field messages.

## Submission via the project's async-task helper

Forms typically delegate submission to the parent (Dialog or Page). The parent wraps the call:

```tsx
const submitMutation = useMutation({
  mutationFn: (data: BillFormData) => BillService.create(data),
  onSuccess: () => toast.success(t('bill.notifications.success.created')),
  onError: () => toast.error(t('bill.notifications.errors.createFailed')),
});

return <BillForm onValidSubmit={(data) => submitMutation.mutate(data)} />;
```

This shape uses TanStack Query's `useMutation` — the de-facto async pattern for React. If the project uses a different helper, follow it.

## Form Errors

- Per-field errors: render `errors.{field}.message` inline (RHF handles this)
- Form-level errors (server-side validation failures): set them via `setError('root', { message })` or display from the mutation's `error` state

## Conventions

- **react-hook-form + zodResolver** for validation (or whatever the project uses — discover)
- **Named exports** for both the component and the `*FormData` interface
- **`onValidSubmit` callback** — form is "dumb"; parent handles the side effect
- **`data-testid`** on every interactive element
- **`disabled={isSubmitting}`** on the submit button

## Key Points

- Forms collect data and emit; they don't call services
- Validation: Zod schemas + zodResolver (or project equivalent)
- Submission: parent's mutation/task helper
- Export the `*FormData` interface for parent type-safety
- See VALIDATOR-001 for Zod schema patterns
- See HOOK-002 for async-work pattern
