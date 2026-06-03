# React Patterns

> Micro-documentation for the React 18+ frontend.
>
> Generic React 18+ + TypeScript + React Router + Zod + TanStack Query + Zustand + Vitest + react-i18next conventions. UI libraries (Radix, MUI, Chakra, shadcn/ui, etc.) and project-specific frameworks ship as separate addon plugins.

## Components

| Pattern | Description |
|---------|-------------|
| [components/COMPONENT-001-conventions.md](./components/COMPONENT-001-conventions.md) | Functional components, props typing, hooks order, naming |
| [components/COMPONENT-002-forms.md](./components/COMPONENT-002-forms.md) | react-hook-form + Zod resolver, controlled forms |
| [components/COMPONENT-003-dialogs.md](./components/COMPONENT-003-dialogs.md) | Modal/dialog components, controlled open state |

## Routing

| Pattern | Description |
|---------|-------------|
| [routes/PAGE-001-pages.md](./routes/PAGE-001-pages.md) | `*Page.tsx` route components, loading/empty/error states |
| [routes/LAYOUT-001-layouts.md](./routes/LAYOUT-001-layouts.md) | Layout components, `<Outlet />`, breadcrumb integration |
| [routes/ROUTE-001-route-definitions.md](./routes/ROUTE-001-route-definitions.md) | React Router v6 data-router API, `RouteObject[]`, lazy imports |
| [routes/ROUTE-002-route-constants.md](./routes/ROUTE-002-route-constants.md) | Route id constants (`{Module}Routes.LIST`) |

## State + Services + Models

| Pattern | Description |
|---------|-------------|
| [stores/STORE-001-zustand-stores.md](./stores/STORE-001-zustand-stores.md) | Zustand stores with selectors, middleware, server vs client state |
| [services/SERVICE-001-service-classes.md](./services/SERVICE-001-service-classes.md) | Static-method service classes, return mapped models |
| [services/SERVICE-002-using-services.md](./services/SERVICE-002-using-services.md) | TanStack Query + custom hooks for service consumption |
| [types/MODEL-001-models.md](./types/MODEL-001-models.md) | Class + `I{Name}` interface + `fromApi(this: void, data)` factory |

## Types + Validation + Enums

| Pattern | Description |
|---------|-------------|
| [types/TYPE-001-types-and-payloads.md](./types/TYPE-001-types-and-payloads.md) | `Create*Payload`, `Update*Payload`, `*Response`, `*ListResponse` |
| [validators/VALIDATOR-001-zod-schemas.md](./validators/VALIDATOR-001-zod-schemas.md) | Zod schemas as factory functions, react-hook-form integration |
| [enums/ENUM-001-i18n-key-enums.md](./enums/ENUM-001-i18n-key-enums.md) | `as const` enums whose values are i18n keys |

## i18n

| Pattern | Description |
|---------|-------------|
| [i18n/I18N-001-translations.md](./i18n/I18N-001-translations.md) | react-i18next, per-module translation trees, hierarchical keys |

## Custom Hooks

| Pattern | Description |
|---------|-------------|
| [hooks/HOOK-001-conventions.md](./hooks/HOOK-001-conventions.md) | `use*` prefix, return typed object, when to extract |
| [hooks/HOOK-002-async-pattern.md](./hooks/HOOK-002-async-pattern.md) | TanStack Query (queries + mutations), inline fallback |

## Testing

| Pattern | Description |
|---------|-------------|
| [REACT-TEST-001-component-tests.md](./REACT-TEST-001-component-tests.md) | Vitest + @testing-library/react, user-event, query priorities |
| [REACT-TEST-002-e2e-tests.md](./REACT-TEST-002-e2e-tests.md) | Playwright, Page Objects, auth helpers, responsive testing |

---

## Tech Stack

- **React** 18+ (functional components + hooks)
- **TypeScript** 5+ (strict mode)
- **React Router** 6+ (data-router API)
- **react-i18next** (translations)
- **Zod** (runtime validation)
- **react-hook-form** + **@hookform/resolvers/zod** (forms)
- **Zustand** (client state)
- **TanStack Query** (server state / data fetching)
- **Vitest** + **@testing-library/react** + **user-event** (unit tests)
- **Playwright** (E2E tests)

## Addons (separate plugins)

The same addon model as Vue applies — UI libraries and project-specific frameworks ship as separate plugins layered on top:

- A React UI library addon (e.g., ****, ****, ****) could contribute Radix/MUI/shadcn component conventions
- A homegrown React framework addon (if one exists) ships separately

See [`docs/addons.md`](../../../docs/addons.md) for the addon mechanism.

## Pattern parity with Vue

The React and Vue pattern sets cover the same concepts so projects can move between frameworks with minimal cognitive overhead:

| Concept | Vue | React |
|---------|-----|-------|
| Component conventions | `components/COMPONENT-001` | `components/COMPONENT-001` |
| Forms | `components/COMPONENT-002` (vue-i18n + Zod) | `components/COMPONENT-002` (react-hook-form + Zod) |
| Dialogs | `components/COMPONENT-003` (defineModel) | `components/COMPONENT-003` (controlled) |
| Hooks / composables | `composables/COMPOSABLE-001/002` | `hooks/HOOK-001/002` |
| Pages | `routes/PAGE-001.md` | `routes/PAGE-001.md` |
| Routes | Vue Router idioms | React Router v6 idioms |
| Stores | Pinia (STORE-001) | Zustand (STORE-001) |
| Services | static class | static class |
| Models | class + I-interface + fromApi | class + I-interface + fromApi |
| Tests | Vitest + @vue/test-utils | Vitest + @testing-library/react |
| Async work | task() composable | TanStack Query |
