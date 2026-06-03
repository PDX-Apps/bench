# Bench Plugin — Architecture (Source of Truth)

> AI-driven full-stack development for Laravel + Vue/React projects.
> Skills do context work, agents do generation, pattern files are the read-only knowledge base.
> Vue and React frontends are first-class peers; the active frontend is selected per project via `--frontend=vue|react|none`. UI libraries and homegrown frameworksship as separate addon plugins.

---

## Core Principles

**Skills gather context. Agents generate code. Patterns are the source of truth.**

- **Skills** catch user intent (e.g. `/controller`, `/vue-page`). Each skill does real work: parses the request, inspects the project (modules, siblings, conventions), resolves ambiguity (one focused question or sane default), then delegates to the matching agent with **enriched structured context** — never raw `$ARGUMENTS`.
- **Agents** are isolated subagent workers. They receive structured context, read ONLY the pattern files relevant to the artifact they generate, scaffold via artisan, implement, and return a concise summary.
- **Workflow agents** orchestrate multi-step work (implementing a SPEC, fixing a bug across files). They embed pattern lookups because subagents cannot spawn other subagents.
- **Component agents** generate one type of artifact (a controller, a Vue component, a migration).
- **Coordinator skills** (`/api`, `/ui`) handle multi-artifact features by delegating to their multi-artifact agent — distinct from the single-artifact granular skills.

The main conversation stays at the **business/feature level**. Pattern files, code generation, and implementation noise live inside agent contexts and never pollute the main thread.

---

## Stack Coverage

| Stack | Skills | Agents |
|-------|--------|--------|
| Laravel backend | 1 orchestrator + 3 utility (`/help`, `/ci`, `/mcp-tools`) + ~30 component | ~5 workflow + ~30 component |
| Vue frontend | 11 component + `/ui` coordinator | ~5 workflow + ~12 component |
| React frontend | 11 component | ~5 workflow + ~12 component |
| **Total** | **~60 skills** (filtered to chosen frontend at install time) | **~70 agents** |

Skills broken down:
- **Coordinators** (multi-artifact): `/api` (HTTP feature), `/ui` (UI feature), `/orchestrate` (workflow)
- **Granular** (single-artifact): everything else

---

## Skill Inventory (49)

### Entry Points + Tooling (4)
- `/orchestrate` — multi-step workflows (exec-spec, bug-fix, refactor, etc.)
- `/help` — list skills by category (or look up a single skill)
- `/ci` — run CI pipeline scoped to module
- `/mcp-tools` — Laravel Boost MCP reference

### Backend Component Skills (32)
**HTTP layer:** `/api` (coordinator), `/controller`, `/request`, `/resource`, `/route`, `/middleware`
**Models:** `/model`, `/query-builder`, `/model-trait`, `/enum`
**Business logic:** `/action`, `/service`
**Database:** `/migration`, `/factory`, `/seeder`, `/cast`
**Events + jobs:** `/event`, `/listener`, `/job`
**Auth:** `/policy`, `/auth-config`
**AI (laravel/ai SDK):** `/ai-agent`, `/ai-tool`
**Other:** `/console`, `/exception`, `/rule`, `/provider`
**Docs:** `/phpdoc`, `/swagger`, `/compliance-log`
**Tests:** `/feature-test`, `/unit-test`

### Frontend Component Skills (13)
**Coordinator:** `/ui` (multi-artifact UI feature)
**Single-artifact:** `/vue-component`, `/vue-page`, `/vue-layout`, `/vue-store`, `/vue-service`, `/vue-model`, `/vue-route`, `/vue-i18n`, `/vue-validator`, `/vue-composable`, `/vue-test`
**Reference:** `/vue-ui-library` (lookup + audit primitives)

---

## Agent Inventory (55)

### Workflow Agents (10) — invoked by `/orchestrate`
**Backend:** `exec-spec`, `update-spec`, `bug-fix`, `refactor`, `new-module`
**Frontend:** `vue-exec-spec`, `vue-update-spec`, `vue-bug-fix`, `vue-refactor`, `vue-new-module`

### Backend Component Agents (32)
Same names as their skills (api, controller, request, resource, route, middleware, model, query-builder, model-trait, enum, action, service, migration, factory, seeder, cast, event, listener, job, policy, auth-config, ai-agent, ai-tool, console, exception, rule, provider, phpdoc, swagger, compliance-log, feature-test, unit-test).

### Frontend Component Agents (13)
ui (coordinator), vue-component, vue-page, vue-layout, vue-store, vue-service, vue-model, vue-route, vue-i18n, vue-validator, vue-composable, vue-test, vue-ui-library.

---

## Pattern File Locations (in the plugin, version-aware)

Patterns live in the plugin as a base + overrides matrix. Build resolves per-file precedence to materialize a final set under `patterns-built/`.

**Base = latest stable.** Older versions are expressed as "rollback" overrides. New projects pick up the latest patterns by default; older projects get the L12 / PHP 8.4 idioms applied via override.

| Location | Contents |
|----------|----------|
| `patterns/laravel/base/` | Canonical Laravel patterns — **L13 + PHP 8.5** — 50 files across 17 categories (incl. `ai/` for laravel/ai SDK) |
| `patterns/laravel/overrides/laravel-12/` | Reverts to L12 idioms (no PHP-attribute controllers/jobs/listeners/policies, no `JsonApiResource`) |
| `patterns/laravel/overrides/php-8.4/` | Reverts to PHP 8.4 idioms (no `clone with`, no pipe operator) |
| `patterns/laravel/overrides/laravel-N+php-M/` | Combined-axis overrides (none currently — collisions are rare) |
| `patterns/frontend/vue/base/` | Canonical Vue 3 patterns (Vue 3.5 + Pinia + vue-i18n + Zod) — 21 generic framework files |
| `patterns/frontend/vue/overrides/{axis-N}/` | Vue single-axis overrides (none currently) |
| `patterns/frontend/react/base/` | Canonical React 18+ patterns (React + TS + React Router + Zustand + TanStack Query + Zod + react-i18next) — 20 generic framework files |
| `patterns/frontend/react/overrides/{axis-N}/` | React single-axis overrides (none currently) |

### Current Overrides (9 total — all rollbacks to older versions)

| Target | File | Why (the override "undoes" the latest idiom for older versions) |
|--------|------|-------------------------------------------------------------------|
| `laravel-12/` | `http/HTTP-001-resource-controllers.md` | L12 lacks `#[Middleware]` + `#[Authorize]` attributes — uses constructor `authorizeResource()` |
| `laravel-12/` | `http/HTTP-003-api-resources.md` | L12 only has `JsonResource` — no `JsonApiResource` |
| `laravel-12/` | `http/HTTP-005-invokable-controllers.md` | L12 wires middleware at route level, no `#[Authorize]` on `__invoke` |
| `laravel-12/` | `http/HTTP-006-grouped-controllers.md` | L12 authorizes via route `->can()`, not `#[Authorize]` per method |
| `laravel-12/` | `jobs/JOB-001-queued-jobs.md` | L12 configures jobs via public properties — no `#[Tries]`/`#[Backoff]`/`#[Timeout]` |
| `laravel-12/` | `listeners/LISTEN-002-queued-listeners.md` | L12 has no `#[WithoutRelations]` attribute |
| `laravel-12/` | `policies/POLICY-001-resource-policies.md` | L12 uses `authorizeResource()` in controller constructor |
| `php-8.4/` | `dto/DTO-001-request-data.md` | PHP 8.4 has no `clone($obj, [...])` — DSL methods use `new self(...all fields...)` |
| `php-8.4/` | `services/SERVICE-002-domain-services.md` | PHP 8.4 has no pipe operator — chain via nested calls or fluent methods |

**Project-specific** spec docs (NOT framework patterns) still live in the user's project at `{project}/docs/modules/{Module}/{rules,validations,events,schema,specs}/`. The plugin only owns framework conventions; the project owns its domain model.

**Resolution precedence** (per file): combined override → single-axis override → base. See `patterns/laravel/README.md` for full details.

**Frontend selection** is a separate axis. `--frontend=vue|react|none` picks which `patterns/frontend/{name}/` subtree the build reads. Auto-detect from `package.json`: `vue` dep → `vue`, `react` dep → `react`, neither → `none`. UI libraries and homegrown frameworksship as separate addon plugins that layer additional overrides on top.

---

## Build Process

Agents read patterns from `patterns-built/` — the materialized output of base + overrides. Run the build whenever versions change.

### Auto-detect (recommended)

```bash
cd /path/to/your/project
/path/to/Bench/scripts/build-patterns.sh --auto
```

The script reads `composer.json` (Laravel + PHP versions) and `package.json` (Vue / React major versions) and resolves overrides to match.

### Explicit

```bash
./scripts/build-patterns.sh --laravel=13 --php=8.5 --frontend=vue --vue=3
./scripts/build-patterns.sh --laravel=12 --php=8.4 --frontend=react
./scripts/build-patterns.sh --laravel=13 --php=8.5 --frontend=none   # backend-only
```

### Single-side

```bash
./scripts/build-patterns.sh --laravel-only --laravel=13 --php=8.5
./scripts/build-patterns.sh --frontend-only --frontend=vue --vue=3
```

### Validation

```bash
./scripts/validate-overrides.sh
```

Checks each override file's `base-hash:` frontmatter against the current base file. Flags overrides whose base has drifted since fork — review before relying on them.

### Output

Materialized pattern set goes to `patterns-built/laravel/` and `patterns-built/frontend/{vue,react}/`. The plugin's agents reference these paths. The build report lists which files came from base vs. overrides for transparency.

---

## Constraints (from Claude Code platform)

1. **Subagents cannot spawn subagents.** Workflow agents must do component work themselves with embedded pattern lookups.
2. **Subagent files are flat** in `agents/` — no subdirectories.
3. **Skills can invoke subagents** via the Task tool. Skills are the entry point from the main conversation.

---

## Two Skill Shapes

### Granular Skill (one artifact)

```
/cast → cast skill
  1. Parse $ARGUMENTS (module, name, single/multi-column, target model)
  2. Inspect (Bash): ls Modules/{Module}/app/Casts/, model exists?
  3. Resolve ambiguity (single vs multi-column unclear → ask one question)
  4. Build context blob {module, name, type, target_models, siblings}
  5. Delegate via Task → cast agent (with blob, NOT $ARGUMENTS)
  6. Synthesize agent return for user
```

### Coordinator Skill (multi-artifact)

```
/api → api skill
  1. Parse (module, resource, operation type: crud/invokable/grouped)
  2. Inspect (controllers/, requests/, resources/, model exists?)
  3. Resolve ambiguity (operation type unclear → ask)
  4. Build context blob with full sibling lists
  5. Delegate via Task → api agent (which generates controller + request + resource + route)
  6. Synthesize at feature level
```

The **api agent** still does multi-artifact generation — but for users who want only one piece, the granular skills (`/controller`, `/request`, etc.) are now available.

---

## Three Invocation Paths

### Path 1: Single-Artifact Direct
```
User: /controller add InviteMemberController (invokable)
  ↓ /controller skill (inspects, resolves type, builds context)
  ↓ Task tool
controller agent (reads HTTP-005 only) → scaffolds, implements
  ↓ Returns "Created InviteMemberController. Auth via ->can() on route."
```

### Path 2: Multi-Artifact Feature
```
User: /api implement endpoint to invite a member
  ↓ /api skill (inspects, resolves CRUD/invokable/grouped, builds full context)
  ↓ Task tool
api agent (reads HTTP-001..006 + DTO patterns as needed) → scaffolds all
  ↓ Returns "Created controller + request + resource + route."
```

### Path 3: Orchestrated Full-Stack
```
User: /orchestrate implement SPEC-014-invite-member (covers API + UI)
  ↓ /orchestrate skill (classifies as exec-spec, full-stack)
  ↓ Task → exec-spec agent (backend, full pattern lookup)
    ↓ controller + request + resource + route + action + migration + tests
  ↓ Task → vue-exec-spec agent (frontend, full pattern lookup)
    ↓ dialog + form + validator + i18n + service method
  ↓ Synthesizes: "Feature complete. API live, UI wired, both sides green."
```

---

## UI Library Integration (Addon Plugins)

UI library patterns (component primitives, design tokens, library-specific wrappers) and framework-wrapper patterns (custom DI containers, scoped services, helper APIs) are **not part of the core plugin**. They ship as separate addon plugins so the core stays generic.

When generating visual components, the core `vue-component`/`vue-page`/`ui` agents discover the project's UI library from sibling components and follow that convention. They do NOT assume any specific lib.

---

## Plugin Directory Structure

```
Bench/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
│
├── skills/                       # 46 skills — all do real context work
│   ├── orchestrate/  ci/  mcp-tools/
│   │
│   ├── # Backend HTTP layer
│   ├── api/  controller/  request/  resource/  route/  middleware/
│   │
│   ├── # Backend models + business logic
│   ├── model/  query-builder/  model-trait/  enum/
│   ├── action/  service/
│   │
│   ├── # Backend database
│   ├── migration/  factory/  seeder/  cast/
│   │
│   ├── # Backend events + jobs
│   ├── event/  listener/  job/
│   │
│   ├── # Backend auth
│   ├── policy/  auth-config/
│   │
│   ├── # Backend other
│   ├── console/  exception/  rule/  provider/
│   │
│   ├── # Backend docs
│   ├── phpdoc/  swagger/  compliance-log/
│   │
│   ├── # Backend tests
│   ├── feature-test/  unit-test/
│   │
│   ├── # Frontend coordinator
│   ├── ui/
│   │
│   ├── # Frontend single-artifact
│   ├── vue-component/  vue-page/  vue-layout/  vue-store/  vue-service/
│   ├── vue-model/  vue-route/  vue-i18n/  vue-validator/
│   ├── vue-composable/  vue-test/
│   │
│   └── # Frontend reference
│       └── vue-ui-library/
│
├── agents/                       # 53 agents (FLAT — no subdirectories)
│   ├── # Workflow (10)
│   ├── exec-spec.md  update-spec.md  bug-fix.md  refactor.md  new-module.md
│   ├── vue-exec-spec.md  vue-update-spec.md  vue-bug-fix.md  vue-refactor.md  vue-new-module.md
│   │
│   ├── # Backend component (30)
│   ├── api.md  controller.md  request.md  resource.md  route.md  middleware.md
│   ├── model.md  query-builder.md  model-trait.md  enum.md
│   ├── action.md  service.md
│   ├── migration.md  factory.md  seeder.md  cast.md
│   ├── event.md  listener.md  job.md
│   ├── policy.md  auth-config.md
│   ├── console.md  exception.md  rule.md  provider.md
│   ├── phpdoc.md  swagger.md  compliance-log.md
│   ├── feature-test.md  unit-test.md
│   │
│   └── # Frontend component (13)
│       ├── ui.md
│       ├── vue-component.md  vue-page.md  vue-layout.md  vue-store.md
│       ├── vue-service.md  vue-model.md  vue-route.md  vue-i18n.md
│       ├── vue-validator.md  vue-composable.md  vue-test.md
│       └── vue-ui-library.md
│
├── hooks/                        # Future: pre/post processing
└── docs/architecture.md               # This file
```

---

## What Changed in the Latest Iteration

**Phase 1 — Fattened all skills.** Skills are no longer 8-line passthroughs. Each skill now:
- Parses the request (extracts module, name, type, intent)
- Inspects the project (Bash, Glob, ls — quick checks, never reads whole files)
- Resolves ambiguity (one focused question or sane default)
- Builds an enriched context blob (the agent doesn't re-discover anything)
- Delegates with the blob (NOT raw `$ARGUMENTS`)
- Synthesizes the agent's return for the user

**Phase 2.1 — Split 8 multi-artifact agents.** The `/api`, `/model`, `/action`, `/event` skills + agents stayed; the `/database`, `/auth`, `/docs`, `/test` skills + agents were dropped. Added 19 new granular skill+agent pairs:
- HTTP: `/controller`, `/request`, `/resource`, `/route`
- Models: `/query-builder`, `/model-trait`, `/enum`
- Service: `/service`
- DB: `/migration`, `/factory`, `/seeder`
- Events: `/listener`
- Auth: `/policy`, `/auth-config`
- Docs: `/phpdoc`, `/swagger`, `/compliance-log`
- Tests: `/feature-test`, `/unit-test`

**Phase 2.2 — UI Library.** 17 new pattern files documenting reusable design tokens and components from `ComponentShowcase.vue`. One new agent (`vue-ui-library`) that knows them all. `vue-component`, `vue-page`, and `ui` agents updated to consult the library first.

---

## Rules

1. **Skills do context work. Agents do generation.** Every skill must inspect, resolve, and enrich before delegating.
2. **Pass enriched context, not raw `$ARGUMENTS`** — agents shouldn't re-discover what the skill already learned.
3. **Read only what you need.** Lookup table → ONE pattern file → implement → done.
4. **Sibling files first.** Before creating something new, check sibling files for existing conventions.
5. **Test every change.** Backend → `composer ci`. Frontend → `npm run test:unit` + `npm run typecheck`.
6. **Workflow agents are self-contained.** They embed pattern lookups (subagents can't spawn subagents).
7. **Coordinator skills (`/api`, `/ui`) for multi-artifact features. Granular skills for single artifacts.**
8. **UI primitives first.** Before generating frontend markup, inspect sibling components for the project's UI library + existing primitives. Don't reinvent.
9. **Backend ≠ Frontend.** PHPUnit/Pest for backend, Vitest for frontend. Laravel patterns for backend, Vue/React patterns for frontend. Never mix.
10. **Full-stack work goes sequentially** — backend first (so the API exists), then frontend (so the UI can consume it).
