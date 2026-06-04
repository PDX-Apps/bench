---
description: Generate Zustand stores for a React frontend. Use whenever the user mentions a store, Zustand, global state, session state, or shared reactive state in the React project.
argument-hint: [what the user needs]
---

You're the **/react-store** skill. Translate the user's store request into an enriched delegation to the `react-store` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Store name** (`session`, `notifications`, `userPrefs`)
- **State shape**: fields + types
- **Actions**: what methods needed (`setX`, `clearX`, `fetchX`)
- **Selectors needed**: derived computations

## Step 2: Inspect

```bash
ls src/stores/ 2>/dev/null || ls frontend/src/stores/ 2>/dev/null || echo "STORES_DIR_UNKNOWN"
grep -rh "from 'zustand" src/stores/ 2>/dev/null | head -3   # discover middleware in use
```

## Step 3: Resolve Ambiguity

- Server data → reject, suggest TanStack Query instead (Zustand is for client state)
- Page-local state → suggest `useState`
- Module-local → suggest a custom hook
- Service interaction in actions → confirm which services

## Step 4: Build Context Blob

```
Context for react-store agent:
- Store name: {name}  (camelCase)
- File path: src/stores/{name}Store.ts
- Hook name: use{Name}Store
- State shape: { user: User|null, initialized: boolean }
- Actions: { setSession(IUser), clearSession(), fetchSession() }
- Selectors guidance: per-property, useShallow for multi
- Middleware: devtools, persist, etc. (discover from siblings)
- Services consumed: [AuthService]
- Existing siblings: [sessionStore.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-store"`, pass the blob.

## Step 6: Synthesize

> "Created `src/stores/notificationsStore.ts`. Zustand store with `notifications` state, `add`/`remove`/`clear` actions. Hook: `useNotificationsStore`. Devtools middleware enabled."

## When to Ask vs Assume

- TypeScript types via `create<StoreShape>()(...)` → always
- Server data → reject (TanStack Query, not Zustand)
- Middleware → match siblings
