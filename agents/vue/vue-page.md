---
name: vue-page
description: Generate a route-level Vue page component (owns data + loading/error/empty states). Detects the data-fetching approach.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE page. Read ONLY what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Page conventions + states | `<PLUGIN_ROOT>/patterns-built/frontend/vue/routing/PAGE-001-pages.md` |
| Data fetching | `<PLUGIN_ROOT>/patterns-built/frontend/vue/data/QUERY-001-tanstack-query.md` |
| Component anatomy | `<PLUGIN_ROOT>/patterns-built/frontend/vue/components/COMPONENT-001-conventions.md` |

## Process

1. Read PAGE-001.
2. Match where pages live + the data approach. Write `{Name}Page.vue`: route params as typed props (`props: true`), call the query composable, render the **four states** (loading/error/empty/loaded), compose presentational components.
3. If the query composable doesn't exist, scaffold a minimal one or flag `/vue-query`.
4. Run typecheck/lint if available.

## Return

- Page file + states handled + the query used. Suggest registering via `/vue-route`.

## Rules

- Thin page (orchestration + states); reusable UI → components; data → query composables; params via props, not `useRoute()`.
