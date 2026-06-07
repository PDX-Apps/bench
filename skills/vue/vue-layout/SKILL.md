---
description: Generate a Vue layout component (the persistent shell — header/nav/footer + <router-view/> or <slot/>). Use when the user wants a layout, app shell, page wrapper, or auth/guest layout.
argument-hint: [layout name + what chrome it has]
---

You're the **/vue-layout** skill. Enrich and delegate to the `vue-layout` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Layout `{Name}Layout`; the chrome (header/nav/footer/sidebar); named slots
- Wiring: parent-route style vs dynamic `meta.layout` — detect/match.

## Step 2: Build context blob
```
- Layout: {Name}Layout.vue
- Chrome: {header/nav/footer/...}
- Slots: {named slots}
- Wiring: {parent-route | dynamic-meta}  (match project; UI lib primitives if present)
```

## Step 3: Delegate
Task tool, `subagent_type: "vue-layout"`, pass the blob.

## Step 4: Synthesize
Report the layout + where <router-view/> renders + how to wire it in routes.
