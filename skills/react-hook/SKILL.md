---
description: Generate React custom hooks (use* functions) for a React frontend. Use whenever the user mentions a custom hook, useX function, reusable React logic, or extracting shared component logic in the React project.
argument-hint: [what the user needs]
---

You're the **/react-hook** skill. Translate the user's hook request into an enriched delegation to the `react-hook` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (shared, or the owning module)
- **Hook name** — `use{Name}`
- **What it returns** — typed object (or tuple if mirroring React's [value, setter])
- **State managed**
- **Effects / cleanup** needed
- **Composes which other hooks?**

## Step 2: Inspect

```bash
ls src/modules/{Module}/hooks/ 2>/dev/null
ls src/hooks/ 2>/dev/null
grep -rh "useQuery\|useMutation" src/hooks/ src/modules/ 2>/dev/null | head
```

## Step 3: Resolve Ambiguity

- Module-specific vs shared → default to module unless cross-cutting
- Pure utility (no state/effects) → reject; suggest `utils/`
- Single use → push back: "Hooks are usually for 3+ usages"

## Step 4: Build Context Blob

```
Context for react-hook agent:
- Module: {Module} (or shared)
- Hook name: use{Name}
- File: src/modules/{Module}/hooks/use{Name}.ts (or src/hooks/)
- Return shape: { summary: BillSummary, refresh: () => Promise<void>, isLoading: boolean }
- Internal state: useState, useMemo
- Other hooks composed: useQuery, useTranslation
- Lifecycle: useEffect with cleanup | none
- Existing siblings: [useBreadcrumbs.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-hook"`, pass the blob.

## Step 6: Synthesize

> "Created `src/hooks/useBillSummary.ts`. Returns `{ summary, refresh, isLoading }`. Wraps `BillService.list()` via `useQuery`."

## When to Ask vs Assume

- Object return (not tuple) → always; tuple only when mirroring React's value/setter
- Return type annotation → always
- `use*` prefix → always
- Pure utility → reject, redirect to `utils/`
