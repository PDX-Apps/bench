---
description: Build an Inertia.js page end-to-end — the Laravel controller (Inertia::render) plus the Vue/React page component and its form. Use on "/inertia", "make an Inertia page for orders", "wire this controller to an Inertia page". Spans backend + frontend.
argument-hint: "[the page/feature, e.g. orders index + show]"
---

You're the **/inertia** skill. Inertia pages span Laravel + frontend, so delegate to the `inertia-page` agent which builds both sides.

The request: **$ARGUMENTS**

## Step 1: Scope
Identify the page(s) and which props each needs. The project's frontend (vue/react) is known from install.

## Step 2: Delegate
Task tool, `subagent_type: "inertia-page"`, passing the page name(s) + the data each shows + any form. For a multi-page feature, spawn one per page (index/show/create/edit), sharing context.

## Step 3: Report
Summarize: the controller methods + `Inertia::render` calls, the page components created (paths), props passed, and any shared/deferred props or routes added.
