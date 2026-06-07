# Changelog

All notable changes to Bench. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

## [Unreleased]

### Added

- **`bench-manager` addon** (`addons/bench-manager/`, replaces the earlier `onboard` addon) — the `/bench-*` toolkit for tailoring Bench to a project. Six commands: `/bench-init` (scan for deviations from Bench's defaults → offer to capture each as a `.bench/` override or slice; never writes `CLAUDE.md`), `/bench-override` (change a bundled pattern/skill/agent), `/bench-slice` (generate a skill→agent→pattern triple for one of your own domains, e.g. `app/Reports/`), and `/bench-list` / `/bench-show` / `/bench-status` (inspect). Backed by authoring agents (`project-scanner`, `pattern-author`, `skill-author`, `agent-author`) sharing a layered-scan methodology. Auto-loaded by `bench init`; opt out with `--no-onboard`.
- **Contribution system** — `.bench/` overrides and addons layer onto core by a `mode:` frontmatter key: `append` (add a section, base stays — upgrade-safe), `anchor` (splice at a named marker), or `replace` (full fork; no `mode:` = replace, backward compatible). One small `append` file can contribute a section to many base files instead of forking each. Spec in `docs/contribution-system.md`; regression harness at `scripts/test-contribution.sh`.
- **Entry-layer delegation** — `/bench` (root router) classifies stack/intent → `/laravel` + `/frontend` routers → component + workflow (`implement`) agents. `/bench-list` / `/bench-show` / `/bench-status` inspect the install.
- **Compact install profile** — `bench init --profile=compact` ships only the routers + `/help` (the routers NL-route to the same agents, so generation is identical). `standard` (all skills) stays the default.
- **Bundled `bench-laravel-boost` addon** (`addons/laravel-boost/`) — Opt-in addon that makes Bench agents aware of [laravel/boost](https://github.com/laravel/boost) MCP tools (database-schema, tinker, list-routes, search-docs, …) and ships a `/boost-install` skill that walks through composer install + `php artisan boost:install` + MCP-server registration with explicit user permission at each state-modifying step. Install with `bench addon add laravel-boost`.
- **Bundled-addon short names** — `bench addon add NAME` now resolves bare names (e.g., `laravel-boost`) by looking under the bench source's `addons/` directory, in addition to taking absolute paths.

### Changed

- **Patterns are stack-neutral and target Laravel 13 / PHP 8.5** in `base/`, with Laravel 12 / PHP 8.4 rollback overrides. Removed the nwidart/`Modules/` assumption — generation is framework-native (`make:*`, `App\`, `app/`). Laravel patterns reorganized into nested groups (`http/{controllers,requests,resources,responses,middleware,routes}/`, `database/{factories,migrations,seeders}/`, `enums/`, `casts/`, `providers/`, …) with new IDs (`CONTROLLER-001`, `MIGRATION-001`, …). L13 per-action authorization (`#[Authorize]` on the controller) is the default; routes carry only mapping + group middleware.
- **Bench no longer writes `CLAUDE.md`.** Project context that affects generation lives in `.bench/` overrides (each pattern carries its own paths); `CLAUDE.md` stays lean and human-owned. (Replaces the old onboard addon's CLAUDE.md generation.)
- **`.bench/` auto-discovery no longer requires a `.bench-addon.yaml` manifest** — it's picked up whenever it contains `patterns/`, `skills/`, or `agents/`, so overrides written by the authoring agents (or by hand) always survive a rebuild.
- **Source-side reorganization**: `skills/` and `agents/` are now grouped by language/framework at the source (`skills/laravel/`, `skills/vue/`, `skills/react/`, `skills/meta/`). The install still gets a flat layout (`skills/<name>/`, `agents/<name>.md`) — Claude Code's expected shape is unchanged. Install-time pruning derives the per-group prune set from the source layout instead of hardcoded lists, so adding a new vue-* or react-* skill in source no longer requires editing `install.sh`.
- **Symmetric `/vue-ui` and `/react-ui` skills (closes v1.0 gating item #4)**: `/ui` was Vue-only — React projects had a `react-ui` agent but no slash command. Renamed `/ui` → `/vue-ui` (skill + agent both); added a parallel `/react-ui` skill that delegates to the existing `react-ui` agent. Naming now matches every other dual-frontend skill (`vue-component`/`react-component`, `vue-page`/`react-page`, …). Pruning at install time auto-selects the correct pair for the active frontend. *Breaking for users who type `/ui`* — switch to `/vue-ui`.
- **Docs rework**: `README.md`, `docs/architecture.md`, and `docs/addons.md` audited and slimmed; each got a top-of-doc table of contents. README no longer duplicates content from `docs/` (dropped redundant `Addons` and `Project structure` sections). Architecture doc no longer carries historical "What Changed in the Latest Iteration" noise and now reflects the current source layout (grouped `skills/` + `agents/`, bundled `addons/` directory). Each bundled addon now ships its own `README.md` at `addons/{name}/README.md`, linked from the main README and `docs/addons.md`.

### Fixed

- **Removed `.claude-plugin/marketplace.json` from the source repo** — it's now generated into each built install by `install.sh`. A source-repo `marketplace.json` (with `source: "./"`) let people `/plugin marketplace add <repo>` and install the **unbuilt, version-agnostic repo** (no resolved `patterns-built/`, no overrides, no addons). Bench is **per-project-built** via `bench init`; the project must be its own git root so the project-local marketplace path (`./.claude/plugins/bench`) resolves.
- **YAML frontmatter parse failures** — a few `description:`/`argument-hint:` values contained an unquoted `: ` (e.g. `(Note: …)`, `[optional: …]`), which YAML reads as a nested mapping; the frontmatter failed to parse and Claude Code refused to register the skill (`/bench` → "Unknown command"). Removed the offending colons in the `/bench`, `/help`, and `/test-runner` skills.
- `bench addon add` and `bench addon remove` previously execed `$TARGET/scripts/install.sh`, but the slim install doesn't ship `scripts/` — both commands broke after the source/install split. Now they resolve `$BENCH_SOURCE` from `.install-source` (same as `bench rebuild`) and exec the source's `install.sh` with `--target=$TARGET`.
- Addon-manifest name extraction used `\s` (a GNU sed extension), which silently no-op'd on macOS BSD sed and left a leading space in the extracted name. Removing an addon by manifest name (`bench addon remove bench-manager`) consequently failed with "Not found". Replaced with POSIX `[[:space:]]*` in `bin/bench`, `scripts/install.sh`, and `scripts/build-patterns.sh`.

## [0.8.0-beta.1] — 2026-06-02

First public beta. Bench is functional end-to-end but hasn't been battle-tested across many real-world projects yet. Treat the API (pattern locations, skill names, addon manifest format, CLI flags) as **soft-stable** until v1.0.0.

### Added

- **Skills + agents + patterns architecture** — 50 Laravel patterns, 20 Vue patterns, 20 React patterns; ~60 skills (slash commands); ~70 agents (workers). Skills/agents filtered to the chosen frontend at install time.
- **Multi-frontend support** — `--frontend=vue|react|none`. Vue and React are first-class peers. React patterns mirror Vue concepts (components, hooks vs composables, routes, stores via Zustand vs Pinia, TanStack Query vs `task()`).
- **Version overrides** — base targets latest (Laravel 13 / PHP 8.5); rollback overrides keep Laravel 12 / PHP 8.4 supported.
- **Addon mechanism** — extensions ship as separate plugins. Project-local extensions auto-discovered at `./.bench/`. Reusable addons via `--addon=PATH`. Addon files merge into `patterns-built/`; addon skills/agents copy into the install with backup-restore on removal.
- **Monorepo-aware install** — when no `composer.json`/`package.json` at the project root, `bench init` scans `apps/`/`packages/`/`services/` one level deep, interactively confirms detected versions.
- **CLAUDE.md auto-read directive** — every workflow agent reads `CLAUDE.md` at the project root before generating, so project-specific layout/conventions override defaults.
- **Slim project install** — source machinery (scripts, raw patterns, docs) stays at the bench source; only runtime artifacts (skills, agents, materialized patterns-built, manifest, bin) get copied into `.claude/plugins/bench/`. Source updates flow through via `rebuild`.
- **Auto-registration** — `init` writes a `pdx-apps` marketplace + `bench@pdx-apps` enable entry into `.claude/settings.json`. Opt out with `--no-register` (manual `/plugin install` path shown either way).
- **CLAUDE.md scaffold** — `init` offers to generate a starter CLAUDE.md from your detected layout if you don't have one.
- **Persistence** — addon paths + detected versions persist in the install so `rebuild` doesn't lose them.
- **Pluggable install location** — `--target=PATH` decouples build-from from install-to. `install.sh` refuses to install "in place" at source (prevents path pollution).

### Known limitations (planned for 1.0)

These are the gating criteria for graduating from beta to stable:

1. **Real Claude Code session validation.** Subagent simulations show the CLAUDE.md-reading directive works as designed, but actual production CC subagent semantics haven't been verified at scale. Need real-world usage to confirm or refine.
2. **React side battle-testing.** Pattern bodies are written, but no real React project has been onboarded yet. Vue side has been tested against a complex monorepo (Laravel + Vue + Electron + Capacitor).
3. **Pest auto-detection.** Tributary uses Pest, not PHPUnit. The current test patterns are PHPUnit-flavored. Need detection + a Pest variant.
4. **`/ui` ↔ `/react-ui` consistency.** `/ui` skill is Vue-flavored; React projects have a `react-ui` agent but no slash command. Either add `/react-ui` skill or make `/ui` detect and route to the right agent.
5. **Process-step examples in Vue/React agents.** Many agent prompts include `src/modules/{Module}/...` as the example path. CLAUDE.md-wins directive resolves it in practice but cleaner if examples were explicitly illustrative ("see CLAUDE.md for your project's actual layout").
6. **Install-script CI.** No automated tests against fake projects. A regression in `init-project.sh` / `install.sh` / `build-patterns.sh` is currently invisible until someone runs `bench init`.
7. **At least one external user.** Validates the install flow, the README's clarity, and the "AI assistants get smarter about your project" promise.

### Out-of-scope for 1.0 (post-v1 backlog)

- Multi-CLI adapters (Gemini CLI, Codex CLI, Cursor). Source layout makes room; not built.
- Public addon registry / `bench addon search` / `bench addon publish`.
- One-line install (`curl | bash` from a hosted endpoint). Requires hosting.
- Asciinema demo / screenshots in README.
- CONTRIBUTING.md, security policy, issue templates.
