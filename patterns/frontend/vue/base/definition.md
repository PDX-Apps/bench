# Vue Patterns

> Micro-documentation for the Vue 3 frontend.
>
> Generic Vue 3 + Pinia + Vue I18n + Zod conventions. UI library and homegrown-framework patterns live in separate addons (, ) when needed.

## Components

| Pattern | Description |
|---------|-------------|
| [components/COMPONENT-001-conventions.md](./components/COMPONENT-001-conventions.md) | Naming, folders (Cards/Dialogs/Forms/Inputs/Sections), `<script setup>` structure |
| [components/COMPONENT-002-forms.md](./components/COMPONENT-002-forms.md) | Form components: input wrapper + Zod schemas, `defineModel`, validSubmit emit |
| [components/COMPONENT-003-dialogs.md](./components/COMPONENT-003-dialogs.md) | Dialog wrapper: `defineModel<boolean>` for visibility, async submit |

## Routing

| Pattern | Description |
|---------|-------------|
| [routes/PAGE-001-pages.md](./routes/PAGE-001-pages.md) | `*Page.vue` route components, lifecycle, loading/empty/error states |
| [routes/LAYOUT-001-layouts.md](./routes/LAYOUT-001-layouts.md) | App/Guest/Landing layouts, breadcrumb integration |
| [routes/ROUTE-001-route-definitions.md](./routes/ROUTE-001-route-definitions.md) | `RouteRecordRaw[]`, auth meta, lazy imports |
| [routes/ROUTE-002-route-constants.md](./routes/ROUTE-002-route-constants.md) | Route name enums (`{Module}Routes.LIST`) |

## State + Services + Models

| Pattern | Description |
|---------|-------------|
| [stores/STORE-001-pinia-stores.md](./stores/STORE-001-pinia-stores.md) | Typed `defineStore<ID, State, Getters, Actions>` |
| [services/SERVICE-001-service-classes.md](./services/SERVICE-001-service-classes.md) | Service classes wrapping HTTP/data access, return mapped models |
| [services/SERVICE-002-using-services.md](./services/SERVICE-002-using-services.md) | Consuming services from components and stores |
| [types/MODEL-001-models.md](./types/MODEL-001-models.md) | Class + `I{Name}` interface + static `fromApi(this: void, data)` factory |

## Types + Validation + Enums

| Pattern | Description |
|---------|-------------|
| [types/TYPE-001-types-and-payloads.md](./types/TYPE-001-types-and-payloads.md) | `Create*Payload`, `Update*Payload`, `*Response`, `*ListResponse` conventions |
| [validators/VALIDATOR-001-zod-schemas.md](./validators/VALIDATOR-001-zod-schemas.md) | Zod schemas as factory functions, form integration |
| [enums/ENUM-001-i18n-key-enums.md](./enums/ENUM-001-i18n-key-enums.md) | `as const` enums whose values are i18n keys (`module::path.to.key`) |

## i18n

| Pattern | Description |
|---------|-------------|
| [i18n/I18N-001-translations.md](./i18n/I18N-001-translations.md) | Per-locale translation trees, hierarchical keys, namespace = module |

## Composables

| Pattern | Description |
|---------|-------------|
| [composables/COMPOSABLE-001-conventions.md](./composables/COMPOSABLE-001-conventions.md) | `use*` prefix, return typed object, when to extract |
| [composables/COMPOSABLE-002-task-pattern.md](./composables/COMPOSABLE-002-task-pattern.md) | Async task composable: standard wrapper for async work in components |

## Testing

| Pattern | Description |
|---------|-------------|
| [VUE-TEST-001-component-tests.md](./VUE-TEST-001-component-tests.md) | Vitest + @vue/test-utils, `data-testid` selectors |
| [VUE-TEST-002-e2e-tests.md](./VUE-TEST-002-e2e-tests.md) | Playwright, auth setup, Page Objects, responsive testing |

---

## Tech Stack

- **Vue** 3.5+ (Composition API + `<script setup>`)
- **Pinia** 3 (state management)
- **Vue Router** 4
- **vue-i18n** 11 (translations)
- **TypeScript** 5.9 (strict mode)
- **Zod** (runtime validation)
- **Vitest** + **Playwright** (testing)

## Addons (separate plugins)

UI library specifics (component primitives, design tokens) and framework-wrapper patterns (custom DI containers, helper APIs) ship as separate addon plugins so the Vue base stays generic. See `docs/addons.md` for the addon mechanism.
