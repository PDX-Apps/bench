# COMPONENT-003-dialogs

## Pattern

Dialog/modal components live in `components/Dialogs/`. They wrap the project's modal primitive (Radix Dialog, MUI Dialog, headless UI Dialog, plain `<dialog>`, etc.), manage open/close state via a prop (parent-controlled), contain a Form (see COMPONENT-002), and call services to persist data.

## Structure

```tsx
import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { BillService } from '../../services/BillService';
import { BillForm, type BillFormData } from '../Forms/BillForm';
import type { Bill } from '../../types/bill.types';

interface BillFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  mode: 'create' | 'edit';
  bill?: Bill;
  onSuccess?: (bill: Bill) => void;
}

export function BillFormDialog({ open, onOpenChange, mode, bill, onSuccess }: BillFormDialogProps) {
  const { t } = useTranslation();

  const submitMutation = useMutation({
    mutationFn: (data: BillFormData) =>
      mode === 'create' ? BillService.create(data) : BillService.update(bill!.id, data),
    onSuccess: (result) => {
      onSuccess?.(result);
      onOpenChange(false);
    },
  });

  if (!open) return null;

  return (
    // Use whatever modal primitive the project provides — plain <dialog>, Radix Dialog,
    // MUI Dialog, headless UI Dialog, etc. Discover from sibling dialogs.
    <dialog open className="dialog" data-testid="bill-form-dialog">
      <article className="dialog-content">
        <header>
          <h2>{mode === 'create' ? t('bill.dialog.createTitle') : t('bill.dialog.editTitle')}</h2>
        </header>

        <section>
          <BillForm
            defaultValues={bill}
            onValidSubmit={(data) => submitMutation.mutate(data)}
          />
          {submitMutation.isError && (
            <p className="error">{t('bill.notifications.errors.saveFailed')}</p>
          )}
        </section>

        <footer>
          <button onClick={() => onOpenChange(false)} data-testid="bill-form-cancel">
            {t('common.cancel')}
          </button>
        </footer>
      </article>
    </dialog>
  );
}
```

## Open/Close Pattern

Use a **controlled component** pattern — the parent owns the open state:

```tsx
function BillsPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  return (
    <>
      <button onClick={() => setDialogOpen(true)}>Add Bill</button>
      <BillFormDialog open={dialogOpen} onOpenChange={setDialogOpen} mode="create" />
    </>
  );
}
```

This matches Radix/headless UI conventions. If the project's modal library uses a different API (imperative `useModal()` hook, etc.), follow that.

## Mode Pattern

Dialogs that handle both create AND edit use a `mode: 'create' | 'edit'` prop:
- `'create'` — empty form, calls `service.create(...)`
- `'edit'` — pre-filled form (from `bill?` prop), calls `service.update(...)`

Title and button labels switch on `mode`.

## Persistent vs Dismissable

- Persistent (user must click cancel/save) — preferred for forms
- Dismissable (click outside / Escape closes) — preferred for read-only displays

How this is configured depends on the modal library. Follow project convention.

## Conventions

- One dialog per concern (don't combine create/edit/delete in one)
- Always emit `onSuccess` for parent data refresh
- Close the dialog from the success handler (`onOpenChange(false)`)
- Show pending state on submit via `mutation.isPending`
- Show task errors with the project's error-display component

## Key Points

- Dialogs are controlled components — parent owns open state
- They contain a Form (COMPONENT-002) and handle the service call
- Use TanStack Query's `useMutation` (or project's async-task helper)
- `mode` prop for create-vs-edit reuse
- Always emit `onSuccess` and close on success
