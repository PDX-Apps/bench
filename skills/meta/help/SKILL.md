---
description: List the Bench plugin's skills organized by category. Use when the user asks "what skills are available", "what can this plugin do", "list skills", or any meta-question about the plugin's capabilities.
argument-hint: [optional: backend | frontend | workflow | category-name]
---

You're the **/help** skill. Show the user the plugin's skill catalog. The user's filter (if any): **$ARGUMENTS**

## Behavior

- No argument → show full catalog grouped by category
- `backend` → show only backend skills
- `frontend` → show only frontend skills
- `workflow` → show only workflow entry points
- A specific skill name (e.g. `controller`, `vue-page`) → show that skill's description in detail

## Catalog (full)

### 🎯 Entry Points + Tooling
- **/orchestrate** `[task description]` — top-level router for multi-step work (specs, bugs, refactors, new modules). Routes to backend OR frontend OR full-stack workflow.
- **/help** `[filter]` — this skill. Lists skills by category.
- **/ci** `[module]` — run the Laravel CI pipeline scoped to a module (lint, format, types, tests).
- **/mcp-tools** — reference for using Laravel Boost MCP tools.

### 🔧 Backend Coordinators (multi-artifact features)
- **/api** `[feature]` — generates the full HTTP stack for a feature: controller + FormRequest + API Resource + route. Ideal when the user describes an endpoint by behavior.

### 🔧 Backend Granular (single-artifact)
**HTTP layer:** `/controller`, `/request`, `/resource`, `/route`, `/middleware`
**Models:** `/model`, `/query-builder`, `/model-trait`, `/enum`
**Business logic:** `/action`, `/service`
**Database:** `/migration`, `/factory`, `/seeder`, `/cast`
**Events + jobs:** `/event`, `/listener`, `/job`
**Auth:** `/policy`, `/auth-config`
**AI (laravel/ai SDK):** `/ai-agent`, `/ai-tool`
**Other:** `/console`, `/exception`, `/rule`, `/provider`
**Docs:** `/phpdoc`, `/swagger`, `/compliance-log`
**Tests:** `/feature-test`, `/unit-test`

### 🎨 Frontend Coordinators
- **/vue-ui** `[feature]` — Vue: generates the full UI stack (page + components + form + dialog + validators + i18n). Symmetric to `/api` on the backend.
- **/react-ui** `[feature]` — React: same as `/vue-ui` but for React projects (with hooks for data fetching).

### 🎨 Frontend — Vue (single-artifact)
**UI structure:** `/vue-component`, `/vue-page`, `/vue-layout`
**State + data:** `/vue-store`, `/vue-service`, `/vue-model`
**Routing + i18n + validation:** `/vue-route`, `/vue-i18n`, `/vue-validator`
**Composables + tests:** `/vue-composable`, `/vue-test`

### 🎨 Frontend — React (single-artifact)
**UI structure:** `/react-component`, `/react-page`, `/react-layout`
**State + data:** `/react-store`, `/react-service`, `/react-model`
**Routing + i18n + validation:** `/react-route`, `/react-i18n`, `/react-validator`
**Hooks + tests:** `/react-hook`, `/react-test`

> The Vue and React skills are parallel — same job, different framework idioms. Use whichever matches your project. `/orchestrate` detects automatically from `package.json`.

## How They Work

**Skills do context work.** They parse the user's request, inspect the project (which module exists? what siblings? what conventions?), resolve any ambiguity, then delegate to a worker agent with structured context.

**Agents do generation.** They run in isolated subagent contexts, read only the relevant pattern files for the artifact they're producing, scaffold via artisan (or manual creation), and return a concise summary.

**Pattern files** are version-aware. They live in the plugin under `patterns/laravel/base/` and `patterns/frontend/{vue,react}/base/` with optional overrides for newer Laravel/PHP/Vue/React versions. UI libraries ship as separate addon plugins. Run `./scripts/build-patterns.sh --auto` from your project to materialize the resolved set.

## Examples

```
/orchestrate implement SPEC-014-invite-member
/api create endpoint to mark a bill paid
/controller add MarkBillPaidController (invokable)
/vue-component create HouseholdMemberCard
/vue-ui build the household member invitation flow
/help backend
/help vue-component
```

## When in doubt

- Describing a **feature** (multiple artifacts) → `/orchestrate` (workflows) or `/api` / `/vue-ui` / `/react-ui` (single-stack feature)
- Wanting **one specific file** → use the matching granular skill (`/controller`, `/vue-store`, etc.)
- Looking up **what's available** → that's me, you're already here

---

If `$ARGUMENTS` is `backend`, show only the Backend sections.
If `$ARGUMENTS` is `frontend`, show only the Frontend sections.
If `$ARGUMENTS` is `workflow`, show only Entry Points + Tooling.
If `$ARGUMENTS` matches a specific skill name (e.g. `controller`, `vue-page`), open that skill's SKILL.md and show its description and argument-hint.
