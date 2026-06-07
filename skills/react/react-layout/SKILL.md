---
description: Generate React layout components (*Layout.tsx — AppLayout, GuestLayout, etc.) for a React frontend. Use whenever the user mentions a layout, app shell, page wrapper, header/sidebar/footer chrome, or layout file in the React project.
argument-hint: [what the user needs]
---

You're the **/react-layout** skill. Translate the user's layout request into an enriched delegation to the `react-layout` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module / location** — `src/layouts/` (project-wide) or per-module layouts/
- **Layout name** — `*Layout.tsx`
- **Type**: full app shell | guest | landing | mobile
- **Chrome**: header? sidebar? footer? breadcrumbs?

## Step 2: Inspect

```bash
ls src/layouts/ 2>/dev/null
ls src/modules/{Module}/layouts/ 2>/dev/null || echo "NO_LAYOUTS_FOLDER"
ls src/stores/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Where to put it → discover project convention
- Composing layout vs full new → ask if delegating
- Chrome pieces → default inline; extract later

## Step 4: Build Context Blob

```
Context for react-layout agent:
- Layout name: {Name}Layout.tsx
- Path: src/layouts/{Name}Layout.tsx
- Type: app-shell | guest | landing | mobile
- Root markup: discover project's UI library (plain div, MUI Box, Radix layouts)
- Chrome: [header, sidebar, footer, breadcrumbs]
- Auth state: useSessionStore() (if exists)
- Breadcrumbs: useBreadcrumbs() (if project has it)
- Document title: useDocumentTitle() reading route.handle.title
- <Outlet /> + <Suspense> wrapping
- Existing siblings: [AppLayout.tsx, GuestLayout.tsx]
```

## Step 5: Delegate

Task tool, `subagent_type: "react-layout"`, pass the blob.

## Step 6: Synthesize

> "Created `src/layouts/AdminLayout.tsx`. Header + sidebar + breadcrumbs. Reads session store. Single `<Outlet />` wrapped in `<Suspense>`."

## When to Ask vs Assume

- Single `<Outlet />` per layout → always one
- `<Suspense>` around `<Outlet />` → always (for lazy pages)
- UI library / primitives → discover from existing layouts; don't assume
