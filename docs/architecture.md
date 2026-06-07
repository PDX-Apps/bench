# Bench — Architecture

How Bench is built internally. Read this if you want to contribute, debug the install pipeline, or write an addon.

For *what* Bench does and *how to use it*, see the [README](../README.md). For addon authoring, see [addons.md](./addons.md).

---

**Contents:** [Core principles](#core-principles) · [Skills, agents, patterns](#skills-agents-patterns) · [Invocation paths](#invocation-paths) · [Pattern resolution](#pattern-resolution) · [Source vs install split](#source-vs-install-split) · [Build pipeline](#build-pipeline) · [Frontend filtering](#frontend-filtering) · [Source directory layout](#source-directory-layout) · [Install directory layout](#install-directory-layout) · [User customization layers](#user-customization-layers) · [Constraints](#constraints) · [Rules](#rules)

---

## Core principles

**Skills gather context. Agents generate code. Patterns are the source of truth.**

- **Skills** catch user intent (`/controller`, `/vue-component`, `/boost-install`). Each skill parses the request, inspects the project (modules, siblings, conventions), resolves ambiguity with one focused question or a sane default, then delegates to its paired agent with **enriched structured context** — never raw `$ARGUMENTS`.
- **Agents** are isolated subagent workers. They receive structured context, read ONLY the pattern files relevant to the artifact they generate, scaffold via artisan (or manual creation), implement, run verification, and return a concise summary.
- **Patterns** are markdown docs that describe how to write a specific artifact (a controller, a Pinia store, a Vue component). The shared knowledge base agents read against.

The main Claude Code conversation stays at the **feature level** — the user describes what they want, agents handle implementation noise, pattern files stay out of the main context window.

---

## Skills, agents, patterns

### Two kinds of skills

| Shape | Example | What it does |
|---|---|---|
| **Granular** (single-artifact) | `/controller`, `/vue-component`, `/migration` | Generates one type of file. Skill parses + inspects + delegates to a 1:1 paired agent. |
| **Router** | `/bench`, `/laravel`, `/frontend` | `/bench` classifies stack + intent and delegates to `/laravel` or `/frontend`, which decompose the request and spawn the right component/workflow agents. The compact-profile tier. |

### Two kinds of agents

| Kind | Example | Notes |
|---|---|---|
| **Component agent** | `controller`, `vue-component`, `migration` | One artifact type. Paired 1:1 with a granular skill. |
| **Workflow agent** | `implement` (with `vue-*` / `react-*` siblings) | Multi-step work (a whole spec/feature). Spawned by `/laravel` / `/frontend`. Embeds pattern lookups directly (subagents can't spawn subagents — see [Constraints](#constraints)). |

### Pattern files

Pattern files are version-aware markdown that lives in the source under `patterns/laravel/`, `patterns/frontend/vue/`, `patterns/frontend/react/`. They're resolved (`base + version overrides + addon contributions`) into `patterns-built/` at install time. Agents read from `patterns-built/`, never from raw `patterns/`.

---

## Invocation paths

### Path 1 — Single artifact (granular skill → component agent)

```
User: /controller add InviteMemberController (invokable)
  ↓ /controller skill (inspects, resolves type, builds context)
  ↓ Task tool
controller agent (reads CONTROLLER-002 only) → scaffolds, implements
  ↓ Returns "Created InviteMemberController. Authorized via #[Authorize] on the action."
```

### Path 2 — Multi-artifact feature (router → component agents)

```
User: /laravel endpoint to invite a member
  ↓ /laravel skill (classifies as an invokable endpoint, decomposes)
  ↓ Task → controller agent, Task → request agent, Task → route agent (each isolated)
  ↓ Returns "Created controller + request + route."
```

### Path 3 — Orchestrated full-stack (workflow agent)

```
User: /bench implement the member-invitation feature (covers API + UI)
  ↓ /bench (classifies full-stack) → /laravel then /frontend
  ↓ /laravel → Task → implement agent (backend; pattern lookups embedded)
    ↓ controller + request + resource + route + action + migration + tests
  ↓ /frontend → Task → vue-implement agent (frontend; pattern lookups embedded)
    ↓ dialog + form + validator + i18n + service method
  ↓ Synthesizes: "Feature complete. API live, UI wired, both sides green."
```

---

## Pattern resolution

Patterns are a layered system: a base set per stack, version-specific overrides that revert idioms for older runtimes, and addon contributions that layer on top.

**Base = latest stable.** Older versions are expressed as "rollback" overrides — new projects pick up the latest patterns by default; older projects get the older idioms applied via override.

### Precedence (per file, most specific wins)

```
1. Combined override          patterns/laravel/overrides/laravel-{L}+php-{P}/{file}
2. Single-axis override       patterns/laravel/overrides/laravel-{L}/{file}
                              patterns/laravel/overrides/php-{P}/{file}
3. Base                       patterns/laravel/base/{file}
4. Addon contribution         addon-N/patterns/laravel/{file}   ← last write wins among addons
```

Frontend resolves on a separate axis: `--frontend=vue|react|none` picks which `patterns/frontend/{name}/` subtree the build reads.

### Currently shipped overrides

| Target | Files | Why |
|---|---|---|
| `laravel-12/` | 7 patterns | L12 lacks PHP-attribute controllers/jobs/listeners/policies + `JsonApiResource` |
| `php-8.4/` | 2 patterns | PHP 8.4 lacks `clone($obj, [...])` and pipe operator |

Run `./scripts/validate-overrides.sh` to check that override files haven't drifted from the base they were forked from.

---

## Source vs install split

Bench has two distinct locations on disk:

- **Source** — where you cloned `bench/`. Contains everything: scripts, raw patterns, docs, addons, README. The maintainer-facing repo.
- **Install** — `.claude/plugins/bench/` inside each project. Contains only **runtime artifacts** the Claude Code plugin needs at execution time: `skills/`, `agents/`, `patterns-built/`, `bin/bench`, `.claude-plugin/`.

Source internals (`scripts/`, raw `patterns/`, `docs/`, `addons/` directories, etc.) **do not get copied** into the install. They stay at source. `bench rebuild` from inside an install reads `.install-source` to find the source location and re-runs the mirror + build.

This keeps each project's install lean and prevents source-only machinery (build scripts, raw patterns matrix) from polluting the plugin directory the user sees.

---

## Build pipeline

A `bench init` (or `bench rebuild`) run goes through these steps in order:

1. **Detect versions** — `--laravel=N --php=N --frontend=X --vue=N`, falling back to auto-detect from `composer.json` + `package.json`, falling back to persisted versions from a prior install.
2. **Mirror runtime essentials** from source → install:
   - `.claude-plugin/`, `bin/`, `hooks/` — straight rsync.
   - `skills/` and `agents/` — walk source groups (`laravel/`, `vue/`, `react/`, `meta/`) and flatten to the install's depth-1 layout.
3. **Reverse the previous addon install** (if any) — restore overwritten core files, remove addon-contributed files.
4. **Copy addon skills/agents** — each registered addon's `skills/` and `agents/` get copied flat into the install. Later addons win on collision.
5. **Substitute `<PLUGIN_ROOT>`** placeholder in skill + agent files with the actual install path.
6. **Build patterns** — resolve `base + overrides + addon patterns` into `patterns-built/`. Addon files merge over core (later addons win).
7. **Prune the inactive frontend** — for a Vue project, walk `skills/react/` + `agents/react/` at source and remove anything by name from the install (and vice versa for React projects). Pruning derives the list from source, so adding new `vue-*` / `react-*` skills doesn't require editing scripts.

The output is `.claude/plugins/bench/` — a slim install Claude Code auto-discovers as a plugin.

---

## Frontend filtering

A Vue project doesn't need `/react-*` slash commands cluttering Claude Code; a React project doesn't need `/vue-*`. Filtering happens at install time:

- **Detection**: `--frontend=X` if passed, otherwise auto-detect from `package.json` (`vue` dep → vue, `react` dep → react, neither → none).
- **Mirror** copies all groups initially.
- **Build** resolves only the active frontend's patterns into `patterns-built/frontend/{vue,react}/`.
- **Prune** walks the inactive frontend group at source and removes matching names from the install's flat `skills/` + `agents/`.

The `/vue-ui` and `/react-ui` coordinator skills work the same way: source ships both, pruning leaves the active one installed.

For backend-only projects (`--frontend=none`), both vue and react are pruned. Only Laravel + meta groups survive.

---

## Source directory layout

```
bench/                                # the source repo
├── bin/bench                         # CLI dispatcher
├── scripts/
│   ├── init-project.sh               # bench init
│   ├── install.sh                    # mirror source → install + path substitution + build + prune
│   ├── build-patterns.sh             # resolve base + version overrides + addon patterns → patterns-built/
│   ├── install-cli.sh                # optional global symlink helper
│   └── validate-overrides.sh         # check version-override hashes against base
│
├── patterns/                         # raw pattern matrix (source-only — never shipped to install)
│   ├── laravel/
│   │   ├── base/                     # 50 files (L13 + PHP 8.5)
│   │   └── overrides/
│   │       ├── laravel-12/           # 7 rollback files
│   │       └── php-8.4/              # 2 rollback files
│   └── frontend/
│       ├── vue/base/                 # 20 files (Vue 3.5 + Pinia + vue-i18n + Zod)
│       └── react/base/               # 20 files (React 18 + TS + React Router + Zustand + TanStack Query + Zod)
│
├── skills/                           # 60 source skills, grouped by stack
│   ├── laravel/                      # 32
│   ├── vue/                          # 12 (incl. vue-ui coordinator)
│   ├── react/                        # 12 (incl. react-ui coordinator)
│   └── meta/                         # routers + help (bench, laravel, frontend, help)
│
├── agents/                           # 71 source agents, grouped by stack
│   ├── laravel/                      # 37
│   ├── vue/                          # 17
│   ├── react/                        # 17
│   └── meta/                         # (empty — meta skills delegate to other agents)
│
├── addons/                           # bundled addons (opt-in unless noted)
│   ├── bench-manager/                # /bench-* project-tailoring toolkit — auto-loaded by bench init
│   └── laravel-boost/                # laravel/boost MCP awareness + /boost-install
│
├── .claude-plugin/
│   └── plugin.json                   # Claude Code plugin manifest
│                                     # (marketplace.json is NOT shipped here — it's generated
│                                     #  into each built install by install.sh; a source-repo
│                                     #  marketplace.json would let people install the unbuilt repo)
│
├── docs/
│   ├── architecture.md               # this file
│   └── addons.md                     # addon authoring spec
│
├── README.md
└── CHANGELOG.md
```

---

## Install directory layout

After `bench init`, the project gets:

```
{project}/
├── .claude/
│   ├── plugins/bench/                # slim install — only runtime artifacts
│   │   ├── .claude-plugin/           # plugin + marketplace manifests
│   │   ├── bin/bench                 # CLI shim that resolves back to source via .install-source
│   │   ├── skills/                   # FLAT (depth-1) — Claude Code's expected shape
│   │   │   ├── laravel/SKILL.md         (router)
│   │   │   ├── controller/SKILL.md
│   │   │   ├── vue-component/SKILL.md   (only one frontend's skills, after pruning)
│   │   │   └── …
│   │   ├── agents/                   # FLAT — *.md files
│   │   │   ├── implement.md
│   │   │   ├── controller.md
│   │   │   └── …
│   │   ├── patterns-built/           # resolved pattern set (base + overrides + addons)
│   │   │   ├── laravel/
│   │   │   ├── frontend/{vue|react}/
│   │   │   └── authoring/            (only if bench-manager is loaded)
│   │   ├── .install-source           # records source path so rebuild can find it
│   │   ├── .install-record           # records install path so re-installs can reverse cleanly
│   │   ├── .install-addons           # list of files copied from addons (for clean removal)
│   │   ├── .install-addons-config    # persisted addon paths (replayed on rebuild)
│   │   ├── .install-addons-backup/   # backups of core files that addons overwrote
│   │   └── .install-versions-config  # persisted version flags
│   └── settings.json                 # plugin registration (extraKnownMarketplaces + enabledPlugins)
│
├── CLAUDE.md                         # project memory — in every Bench agent's context (you author this; Bench never writes it)
└── .bench/                           # project-local extensions (auto-discovered; commit it)
    ├── patterns/…                    #   overrides + new patterns
    ├── skills/…                      #   custom slash commands
    ├── agents/…                      #   custom workers
    └── .bench-addon.yaml             #   OPTIONAL — discovery works without it
```

Source organization (grouped skills/agents, raw pattern matrix) is hidden from the user — they only see the flat, materialized install.

---

## User customization layers

Bench is designed so users can override any bundled default for their project without forking the source repo. Three layers, in increasing scope:

### Layer 1 — `CLAUDE.md` (project memory)

Free-form markdown at the project root. Claude Code injects it into every agent's context. Document monorepo layout, test framework, naming rules, domain language — anything project-specific. **Bench never writes or overwrites it** (agents don't even carry a "read CLAUDE.md" step — it's auto-injected). Conventions that affect *generation* belong in `.bench/` overrides (Layer 2), where each pattern carries its own paths; that keeps `CLAUDE.md` lean and human-owned.

### Layer 2 — `.bench/` (project-local addon, auto-discovered)

The home for everything project-specific — pattern overrides, custom skills, custom workers. Lives at `{project}/.bench/`; **auto-discovered whenever it contains `patterns/`, `skills/`, or `agents/`** (a `.bench-addon.yaml` manifest is optional). Travels with the project repo — commit it.

Contributions layer onto the bundled base **by `mode:` frontmatter** (see [contribution-system.md](./contribution-system.md)):

- **`append`** (default) — add a section/convention; the base stays. Upgrade-safe.
- **`anchor`** — splice into a named marker in the base.
- **`replace`** (no `mode:` = legacy) — a full fork at the mirrored path (e.g. `.bench/patterns/laravel/http/controllers/CONTROLLER-001-resource.md` replaces the bundled one). Drifts on upgrade; use only when the project genuinely contradicts the base.

The bundled [`bench-manager`](../addons/bench-manager/README.md) addon produces these without manual file editing:

- `/bench-list [patterns|skills|agents]` · `/bench-show <type> <name>` — discover + inspect
- `/bench-override <change>` — change a bundled default (routes to `pattern-author` / `skill-author` / `agent-author`, which pick the lightest contribution mode)
- `/bench-slice <domain>` — generate a skill→agent→pattern triple for one of your own domains
- `/bench-init` — scan the project for deviations and offer to capture each

So the user can say "I prefer global helpers over DI" or "teach Bench my `app/Reports/` domain" without remembering paths or precedence rules.

### Layer 3 — reusable addons (multi-project)

Same shape as `.bench/` plus a `.bench-addon.yaml` manifest, but lives in its own repo and gets registered per-project via `bench addon add`. For conventions shared across multiple projects you maintain (an internal "company style" addon) or framework-specific extensions (Filament, Inertia, Quasar). See [addons.md](./addons.md) for the authoring spec.

### Precedence

For any given file path, last write wins:

```
core base
  ↓ overridden by
core version overrides (active L/PHP/Vue axis)
  ↓ overridden by
reusable addon patterns (in declaration order — later --addon flags win)
  ↓ overridden by
project-local .bench/  (auto-discovered last → always wins)
  ↓ overridden by
CLAUDE.md prose  (read by agents at runtime, supersedes any baked-in default)
```

The cumulative effect: a Bench install is **opinionated by default** (the bundled patterns reflect the maintainer's "right way to do X") but **fully customizable per-project** through any of these layers, with no source forking.

---

## Constraints

These are Claude Code platform constraints that shaped Bench's design:

1. **Subagents cannot spawn subagents.** That's why workflow agents (`implement`, etc.) embed their own pattern lookups instead of delegating to component agents.
2. **Subagent files are flat** in `agents/` at the install — no subdirectories. Source groups them for organization, but the mirror flattens.
3. **Skills can invoke subagents** via the Task tool. Skills are the entry point from the main conversation.

---

## Rules

These apply to every skill + agent in Bench. New contributions should follow them.

1. **Skills do context work. Agents do generation.** Every skill must parse → inspect → resolve ambiguity → enrich before delegating.
2. **Pass enriched context, not raw `$ARGUMENTS`** — agents shouldn't re-discover what the skill already learned.
3. **Read only what you need.** Agents resolve to ONE pattern file (or a small set) → implement → done. Never load the whole patterns directory.
4. **Sibling files first.** Before creating something new, check sibling files for existing conventions.
5. **Verify what you generate.** Backend → `composer ci` (or `pint` + `phpstan` + `pest` scoped to the new files). Frontend → `vitest` + `tsc`.
6. **Workflow agents are self-contained.** Embed pattern lookups (subagents can't spawn subagents).
7. **Coordinator skills for multi-artifact features. Granular skills for single artifacts.** Don't bundle unrelated artifacts in one skill.
8. **UI primitives first.** Before generating frontend markup, inspect sibling components for the project's UI library + existing primitives. Don't reinvent.
9. **Backend ≠ Frontend.** PHPUnit/Pest for backend; Vitest for frontend. Laravel patterns for backend; Vue/React patterns for frontend. Never mix.
10. **Full-stack work goes sequentially.** Backend first (so the API exists), then frontend (so the UI can consume it).
