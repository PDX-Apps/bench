---
description: Generate Pinia stores (typed defineStore) for a Vue 3 frontend. Use whenever the user mentions a store, Pinia, global state, session state, or shared reactive state in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-store** skill. Translate the user's store request into an enriched delegation to the `vue-store` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Store name** (`session`, `notifications`, `userPrefs`)
- **State shape**: which fields, what types
- **Actions**: what methods are needed (`setX`, `clearX`, `fetchX`)
- **Getters**: derived values

## Step 2: Inspect

```bash
ls src/stores/ 2>/dev/null || ls frontend/src/stores/ 2>/dev/null || echo "STORES_DIR_UNKNOWN"
```

## Step 3: Resolve Ambiguity

- Module-local vs global → stores are typically global. Confirm if module-local is needed (usually a composable suffices).
- "Make a store for X local data" → suggest composable + `ref`s instead.
- Service interaction → confirm which services the actions call.

## Step 4: Build Context Blob

```
Context for vue-store agent:
- Store name: {name}  (lowercase camelCase)
- File path: src/stores/{name}Store.ts
- Composable name: use{Name}Store
- State shape: { user: User|null, initialized: boolean }
- Getters: { isAuthenticated, getUser, isInitialized }
- Actions: { setSession(IUser), clearSession(), fetchSession() }
- Services consumed: [AuthService, ApiService]  (project's service-access convention)
- HMR block: yes (Vite projects)
- Existing siblings: [sessionStore.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "vue-store"`, pass the blob.

## Step 6: Synthesize

> "Created `src/stores/notificationsStore.ts`. Typed `defineStore<'notifications', State, Getters, Actions>`. Actions call `NotificationService.fetchAll()`. HMR block included. Composable: `useNotificationsStore()`."

## When to Ask vs Assume

- Typed generic form → always
- HMR block (Vite) → always
- Module-local store → recommend composable instead unless cross-component sharing required
