# Vue Patterns

Framework patterns for the Vue side of the plugin.

## Layout

```
vue/
├── base/                       # Canonical pattern set
│   ├── _meta.yaml              # Declares which versions this base targets
│   ├── components/  routes/  services/  stores/
│   ├── types/  validators/  enums/  i18n/
│   ├── composables/
│   ├── definition.md
│   └── VUE-TEST-001..002 (testing)
└── overrides/
    └── vue-{N}/                # Vue major version overrides (e.g., for Vue 4)
```

## Resolution

Same precedence rules as Laravel, single axis here (Vue major version):

1. `overrides/vue-{N}/{file}` when active
2. `base/{file}` fallback

Build output lands in `patterns-built/frontend/vue/`. Agents read from there.

## Why a single axis?

- **Vue** — Vue 4 will eventually break things; that's the override path
- **Pinia / vue-i18n / Vue Router / TypeScript** — usually backwards-compatible enough that overrides aren't needed; covered by base bumps
- **UI libraries** (Quasar, Vuetify, Radix, etc.) — out of scope for core; ship as separate addon plugins

## Override File Format

Same as Laravel side — see `patterns/laravel/README.md` for the full format.
