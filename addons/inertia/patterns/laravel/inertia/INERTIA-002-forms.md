# Inertia forms

Submit with the **`useForm`** helper — it manages data, `processing`, and server `errors` (Laravel validation flows back automatically on a redirect-back).

## Vue (`@inertiajs/vue3`)

```vue
<script setup>
import { useForm } from '@inertiajs/vue3'

const form = useForm({ reference: '', status: 'pending' })
const submit = () => form.post('/orders', { onSuccess: () => form.reset() })
</script>

<template>
  <form @submit.prevent="submit">
    <input v-model="form.reference">
    <div v-if="form.errors.reference">{{ form.errors.reference }}</div>
    <button type="submit" :disabled="form.processing">Create</button>
  </form>
</template>
```

## React (`@inertiajs/react`)

```tsx
import { useForm } from '@inertiajs/react'

export function CreateOrder() {
  const { data, setData, post, processing, errors } = useForm({ reference: '', status: 'pending' })
  const submit = (e: React.FormEvent) => { e.preventDefault(); post('/orders') }
  return (
    <form onSubmit={submit}>
      <input value={data.reference} onChange={e => setData('reference', e.target.value)} />
      {errors.reference && <div>{errors.reference}</div>}
      <button type="submit" disabled={processing}>Create</button>
    </form>
  )
}
```

## Conventions

- **`useForm({...})`** owns form state; submit via `form.post/put/patch/delete(url, options)`.
- **`form.errors`** is populated from Laravel validation on a redirect-back — no manual error wiring; the controller validates (FormRequest) and redirects.
- **`processing`** disables the submit; `form.reset()` / `onSuccess` for post-submit; `form.transform()` to reshape before send.
- For edits, initialize `useForm` with the current values and `put`/`patch`.

## Don't

- Don't hand-roll fetch + error state — `useForm` does it. Don't validate on the client only — the server FormRequest is the source of truth.

## See also

- [INERTIA-001-pages](INERTIA-001-pages.md) · core: `<PLUGIN_ROOT>/patterns-built/laravel/http/requests/REQUEST-001-form-requests.md`
