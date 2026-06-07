---
description: Generate a React layout component (persistent shell with <Outlet/> — header/nav/footer). Use when the user wants a layout, app shell, page wrapper, or auth/guest layout.
argument-hint: [layout name + what chrome it has]
---

You're the **/react-layout** skill. Enrich and delegate to the `react-layout` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Layout `{Name}Layout`; chrome (header/nav/footer/sidebar)
## Step 2: Build context blob
```
- Layout: {Name}Layout.tsx
- Chrome: {header/nav/footer}
- Styling/UI: {detect + match}
```
## Step 3: Delegate
Task tool, `subagent_type: "react-layout"`, pass the blob.
## Step 4: Synthesize
Report the layout + where <Outlet/> renders + how to wire it as a route.
