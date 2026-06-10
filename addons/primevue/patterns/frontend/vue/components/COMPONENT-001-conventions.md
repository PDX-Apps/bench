---
mode: append
---

## PrimeVue (this project uses primevue)

Compose UI from **PrimeVue** components — don't hand-roll buttons, inputs, dialogs, tables, or overlays. Import per-component (`import Button from "primevue/button"`) or rely on the project's global registration / auto-import resolver — match what existing components do.

Catalog you'll reach for: `Button`, `InputText`/`Textarea`/`InputNumber`, `Select` (single) / `MultiSelect`, `DatePicker`, `AutoComplete`, `Checkbox`/`ToggleSwitch`/`RadioButton`, `DataTable`+`Column`, `Dialog`, `Drawer`, `Popover`, `Menu`/`Menubar`, `Tabs`, `Card`, `Message`, `Toast`, `ConfirmDialog`.

> **v4 renames** (don't use the v3 names): `Dropdown`→`Select`, `Calendar`→`DatePicker`, `Sidebar`→`Drawer`, `InputSwitch`→`ToggleSwitch`, `OverlayPanel`→`Popover`.

### Variants via props

Use `severity` (`secondary`/`success`/`info`/`warn`/`help`/`danger`/`contrast`), `variant` (`text`/`outlined`), and `size` — not custom classes:

```vue
<Button label="Save" />
<Button label="Cancel" severity="secondary" variant="outlined" @click="visible = false" />
```

### Dialog (controlled via `v-model:visible`)

```vue
<script setup lang="ts">
import { ref } from "vue"
import Dialog from "primevue/dialog"
import Button from "primevue/button"
const visible = ref(false)
</script>

<template>
  <Button label="Edit" @click="visible = true" />
  <Dialog v-model:visible="visible" modal header="Edit order" :style="{ width: '28rem' }">
    <!-- form -->
  </Dialog>
</template>
```

### DataTable for tabular data

```vue
<DataTable :value="orders" paginator :rows="10" sortMode="multiple" dataKey="id">
  <Column field="reference" header="Reference" sortable />
  <Column field="total" header="Total" sortable />
</DataTable>
```

Prefer `DataTable` (sorting/filtering/pagination/selection built in) over a hand-built table.

### Forms — `@primevue/forms` + Zod

PrimeVue ships its own form layer: `<Form>` with a resolver and per-field `<Message>`:

```vue
<script setup lang="ts">
import { Form } from "@primevue/forms"
import { zodResolver } from "@primevue/forms/resolvers/zod"
import { z } from "zod"
const resolver = zodResolver(z.object({ reference: z.string().min(1, "Required") }))
function onSubmit({ valid, values }) { if (valid) { /* … */ } }
</script>

<template>
  <Form :resolver="resolver" :initialValues="{ reference: '' }" @submit="onSubmit" v-slot="$form">
    <InputText name="reference" fluid />
    <Message v-if="$form.reference?.invalid" severity="error" size="small" variant="simple">
      {{ $form.reference.error?.message }}
    </Message>
    <Button type="submit" label="Save" />
  </Form>
</template>
```

(If the project standardized on vee-validate instead, follow that — but PrimeVue Forms is the native default.)

### Services — Toast & Confirm

Register the service plugin once (`app.use(ToastService)` / `ConfirmationService`), drop the `<Toast />` / `<ConfirmDialog />` host in the layout, then call the composable:

```ts
import { useToast } from "primevue/usetoast"
const toast = useToast()
toast.add({ severity: "success", summary: "Saved", life: 3000 })
```

`useConfirm()` drives `<ConfirmDialog />` the same way for destructive actions.

### Customizing internals

Tweak a component's inner DOM with **`pt`** (PassThrough) — pass classes/attrs to named parts — and per-component design tokens via the **`dt`** prop. Don't reach into `.p-*` CSS selectors.

### Don't

- Don't use v3 component names (`Dropdown`/`Calendar`/`Sidebar`/`OverlayPanel`).
- Don't hand-roll tables/inputs/overlays PrimeVue ships; don't override deep `.p-*` CSS — use `pt`/`dt`.
- Don't hard-code colors — use the theme's design tokens (see theming).
