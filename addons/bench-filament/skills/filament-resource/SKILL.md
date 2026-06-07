---
description: Generate a Filament 3 admin-panel Resource (form schema + table) for a model. Use when the user mentions Filament, an admin panel / back-office CRUD, a Filament resource, a Filament form or table, filters, or a relation manager.
argument-hint: [model + the fields/columns/filters you want]
---

You're the **/filament-resource** skill. Turn the request into an enriched delegation to the `filament-resource` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The model the resource manages (e.g. `Order`, `Subscription`).
- Form fields + their types/validation (text, select+options, relationship, date, toggle, file).
- Table columns (which to show, searchable/sortable), filters, and any custom row/bulk actions.
- Whether a View page, soft-deletes, or relation managers are wanted.

## Step 2: Resolve
- Model missing → suggest `/model` first.
- Fields/columns unclear → ask which attributes go on the form and which appear in the table.
- Detect where the project's panel keeps resources (custom namespace?) so the agent matches it.

## Step 3: Build context blob
```
- Resource: {Model}Resource  (model: {Model})
- Form: [reference: text required, status: select(pending,paid,cancelled), product_id: relationship(product,name)]
- Table columns: [reference (searchable), status (badge), total (money,sortable), created_at (dateTime)]
- Filters: [status]   Actions: [Edit, Delete, + custom markPaid?]
- Flags: --view? --soft-deletes? relation managers?
```

## Step 4: Delegate
Task tool, `subagent_type: "filament-resource"`, pass the blob.

## Step 5: Synthesize
Report the resource (form + table), pages, any relation managers, and remind to confirm a model policy gates access.
