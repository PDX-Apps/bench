# React Patterns

> The generic React + TypeScript base. Settled conventions, with **explicit deferral** on the plural concerns (styling, UI library, data layer, routing flavor, folder structure). Opinionated choices ship as **addons**.

## Philosophy — what the base commits to, and what it defers

Like the Vue base, this is deliberately thin — frontend has few universal conventions:

- **Prescribed** (settled in modern React): **function components + hooks + TypeScript** (strict), **Zustand** for client state, **React Router** for routing, **Vite** + **Vitest** + **Testing Library** for tests, **TanStack Query (React Query)** for server state, **react-hook-form + Zod** for forms.
- **Deferred — detect and match the project:**
  - **Styling** — Tailwind, CSS Modules, or a UI library. The base teaches *structure*; the agent detects from `package.json` + existing files and matches. Greenfield default: **CSS Modules** (zero-config with Vite) + CSS custom properties. See [styling/STYLE-001](./styling/STYLE-001-conventions.md).
  - **Component library** — none/headless in the base. shadcn/ui, MUI, Chakra, Radix, etc. are **addons**.
  - **Routing flavor** — React Router (base); TanStack Router or a framework router (Next.js/Remix) as variants/addons.
  - **Folder structure** — feature/domain folders for non-trivial apps; agent matches the project (flat-by-type is fine for small apps).
  - **Meta-framework** — base assumes a plain **Vite SPA**. Next.js / Remix are separate variants (addons).

> **Detect-and-match is the core move.** A generated component must look like the team's other components — same styling system, same folder, same data approach. Greenfield → zero-dependency default, stated.

## Patterns

| Area | Pattern |
|------|---------|
| Components | [components/COMPONENT-001-conventions.md](./components/COMPONENT-001-conventions.md) · [components/COMPONENT-002-forms.md](./components/COMPONENT-002-forms.md) |
| Hooks | [hooks/HOOK-001-conventions.md](./hooks/HOOK-001-conventions.md) |
| State | [state/STORE-001-zustand.md](./state/STORE-001-zustand.md) |
| Data fetching | [data/QUERY-001-tanstack-query.md](./data/QUERY-001-tanstack-query.md) |
| Routing | [routing/ROUTE-001-routes.md](./routing/ROUTE-001-routes.md) · [routing/PAGE-001-pages.md](./routing/PAGE-001-pages.md) · [routing/LAYOUT-001-layouts.md](./routing/LAYOUT-001-layouts.md) |
| Types | [types/TYPE-001-types.md](./types/TYPE-001-types.md) |
| Validation | [validation/VALIDATOR-001-zod.md](./validation/VALIDATOR-001-zod.md) |
| Styling | [styling/STYLE-001-conventions.md](./styling/STYLE-001-conventions.md) |
| i18n (optional) | [i18n/I18N-001-react-i18next.md](./i18n/I18N-001-react-i18next.md) |
| Testing | [testing/TEST-001-vitest-rtl.md](./testing/TEST-001-vitest-rtl.md) |

## Tech stack (base)

- **React** 18/19 (function components + hooks) · **TypeScript** 5.x (strict)
- **Zustand** (client state) · **React Router** v6/v7 (routing)
- **Vite** · **Vitest** + **@testing-library/react** (unit/component tests)
- **TanStack Query** (React Query) for server state · **react-hook-form** + **Zod** for forms
- Styling: project's choice (base default CSS Modules + CSS variables)

## Addons (opt-in, per project)

- **Styling:** `tailwind`
- **UI libraries:** `shadcn` · `mui` · `chakra` · `radix`
- **Data:** (React Query ships in base)
- **Routing:** `tanstack-router`
- **E2E testing:** `bench-playwright` (the base ships Vitest + Testing Library)
- **Meta-framework:** `nextjs` · `remix`

A project installs only the addons matching its stack; the agents generate that flavour instead of the generic base.
