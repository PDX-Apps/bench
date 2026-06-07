---
description: Generate Vue layout components (*Layout.vue — AppLayout, GuestLayout, etc.) for a Vue 3 frontend. Use whenever the user mentions a layout, app shell, page wrapper, header/sidebar/footer chrome, or layout file in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-layout** skill. Translate the user's layout request into an enriched delegation to the `vue-layout` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module / location** — layouts in `src/layouts/` (project-wide) or top-level App/Auth/Landing module
- **Layout name** — `*Layout.vue`
- **Type**: full app shell | guest | landing/marketing | mobile-specific
- **Chrome**: header? sidebar? footer? breadcrumbs?

## Step 2: Inspect

```bash
ls src/layouts/ 2>/dev/null
ls src/modules/{Module}/layouts/ 2>/dev/null || echo "NO_LAYOUTS_FOLDER"
ls src/stores/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Where to put it → discover project's convention
- Composing layout vs full new layout → ask if delegating
- Chrome pieces → default inline for first version; extract later

## Step 4: Build Context Blob

```
Context for vue-layout agent:
- Layout name: {Name}Layout.vue
- Path: src/layouts/{Name}Layout.vue
- Type: app-shell | guest | landing | mobile
- Root markup: discover project's UI library convention (plain div, Quasar q-layout, Vuetify v-app)
- Chrome: [header, sidebar, footer, breadcrumbs]
- Auth state: useSessionStore() (if project has one)
- Breadcrumbs: useBreadcrumbs() (if project has one)
- Page title: route.meta.title
- Existing siblings: [WebAppLayout.vue, AppLayout.vue]
```

## Step 5: Delegate

Task tool, `subagent_type: "vue-layout"`, pass the blob.

## Step 6: Synthesize

> "Created `src/layouts/AdminLayout.vue`. Header + sidebar + breadcrumbs. Reads session store. Single `<router-view />` for child pages."

## When to Ask vs Assume

- Single `<router-view />` per layout → always one
- UI library / component primitives → discover from existing layouts; don't assume Quasar or any specific lib
- Session/breadcrumb composables → only assume if they exist in the project
