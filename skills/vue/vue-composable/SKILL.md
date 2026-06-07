---
description: Generate Vue composables (use* functions) for a Vue 3 frontend. Use whenever the user mentions a composable, useX function, reusable Vue logic, or extracting shared component logic in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-composable** skill. Translate the user's composable request into an enriched delegation to the `vue-composable` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Core/shared, or the owning module)
- **Composable name** — `use{Name}`
- **What it returns** — typed object (always object, never tuple)
- **Reactive state** managed
- **Lifecycle hooks** needed
- **Provides/inject** for cross-component context?

## Step 2: Inspect

```bash
ls src/modules/{Module}/composables/ 2>/dev/null
ls src/composables/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module-specific vs shared → default to module-specific unless clearly cross-cutting
- Pure utility (no reactivity) → reject as composable; suggest `utils/`
- Used by 1-2 components only → "Composables are usually for 3+ usages. Inline or extract anyway?"

## Step 4: Build Context Blob

```
Context for vue-composable agent:
- Module: {Module} (or shared)
- Composable name: use{Name}
- File: src/modules/{Module}/composables/use{Name}.ts
- Return shape: { breadcrumbs: ComputedRef<BreadcrumbItem[]> }
- Internal state: ref(), computed()
- Vue Router composables used: useRoute, useRouter (if relevant)
- Other composables composed: [...]
- Lifecycle: onMounted | onUnmounted | none
- Provide/inject: yes (Symbol key + provide/inject exported) | no
- Existing siblings: [useBreadcrumbs.ts, useGSAP.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "vue-composable"`, pass the blob.

## Step 6: Synthesize

> "Created `src/composables/useBillSummary.ts`. Returns `{ summary: ComputedRef<BillSummary>, refresh: () => Promise<void>, isLoading: Ref<boolean> }`. Wraps `BillService.list()` with reactive loading state."

## When to Ask vs Assume

- Object return (not tuple) → always
- Explicit return type annotation → always
- `use*` prefix → always
- Pure utility → reject and redirect to `utils/`
