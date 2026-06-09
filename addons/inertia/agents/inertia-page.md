---
name: inertia-page
description: Build ONE Inertia page end-to-end — the Laravel controller (Inertia::render with props) and the matching Vue/React page component + form (useForm). Reads INERTIA-001/002.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You build ONE Inertia page across both sides: the Laravel controller render and the frontend page component. Match the project's stack + conventions.

## Pattern Lookup

| Need | Read |
|------|------|
| Laravel side (render, shared/deferred props) | `<PLUGIN_ROOT>/patterns-built/laravel/inertia/INERTIA-001-pages.md` |
| Forms (useForm, validation flow) | `<PLUGIN_ROOT>/patterns-built/laravel/inertia/INERTIA-002-forms.md` |
| Page navigation (no client router) | `<PLUGIN_ROOT>/patterns-built/frontend/{vue,react}/routing/ROUTE-001-routes.md` |
| Page data is props (no query lib) | `<PLUGIN_ROOT>/patterns-built/frontend/{vue,react}/data/QUERY-001-tanstack-query.md` |

## Process

1. Read the patterns for the project's frontend (vue or react). Inspect `<!--bench:var:inertia_pages_dir;default:resources/js/Pages-->/` for the project's structure + `createInertiaApp` resolve convention.
2. **Laravel**: add/extend the controller method returning `Inertia::render('Dir/Page', [...props])` — pass API Resources/paginators, not raw models; defer expensive props; register the route.
3. **Frontend**: create `<!--bench:var:inertia_pages_dir;default:resources/js/Pages-->/{Dir}/{Page}.{vue,tsx}` that reads the props; compose components; for collections add empty state + pagination links from the paginator meta.
4. **Forms**: use `useForm` (post/put), surface `errors` (populated from the FormRequest on redirect-back), disable on `processing`.
5. Don't introduce a client router or query library — navigation is `<Link>`/`router`, data is props.

## Return

- The controller method + render call, the page component path, props passed (+ any deferred/shared), routes added, and the form wiring. Note anything left to do (FormRequest, Resource).

## Rules

- Page data is props — no TanStack Query/service layer for it. Navigation via `<Link>`/`router` — no vue-router/react-router. Pass Resources, not raw models. Validation lives in the FormRequest; the page just shows `errors`. Match the project's Pages/ layout + styling.
