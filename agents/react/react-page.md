---
name: react-page
description: Generate a route-level React page component (owns data + loading/error/empty states).
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE page. Read ONLY what you need.

## Pattern Lookup
| Need | Read |
|------|------|
| Page conventions + states | `<PLUGIN_ROOT>/patterns-built/frontend/react/routing/PAGE-001-pages.md` |
| Data fetching | `<PLUGIN_ROOT>/patterns-built/frontend/react/data/QUERY-001-tanstack-query.md` |
| Component anatomy | `<PLUGIN_ROOT>/patterns-built/frontend/react/components/COMPONENT-001-conventions.md` |

## Process
1. Read PAGE-001.
2. Match where pages live + the data approach. Write `{Name}Page.tsx` (default export): `useParams` for params, call the query hook, render the four states, compose components.
3. If the query hook is missing, scaffold a minimal one or flag `/react-query`.
4. Run typecheck/lint if available.

## Return
- Page + states handled + query used. Suggest registering via `/react-route`.

## Rules
- Thin page (orchestration + states); reusable UI → components; data → query hooks.
