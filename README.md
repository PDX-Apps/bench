# Bench

> Teach AI coding assistants the conventions of *your* Laravel + Vue/React project — once, then they generate code that fits.

**Status: beta (v0.8.x).** Functional end-to-end; not battle-tested across many projects yet. See [CHANGELOG.md](./CHANGELOG.md) for what's in this release + the gating criteria for v1.0.0.

Most AI coding assistants generate generic-best-practices code. That works for greenfield, but real projects have their own monorepo layouts, framework versions, test frameworks, UI libraries, file conventions, naming rules. Bench is a pluggable kit of agents + slash commands + framework knowledge that adapts to *your* project, so AI-generated code lands in the right place, in the right shape, the first time.

Built for [Claude Code](https://docs.claude.com/en/docs/claude-code) today. Designed to extend to other AI CLIs.

**[Quickstart](#quickstart)** · **[How it works](#how-it-works)** · **[Configuring per project](#configuring-per-project)** · **[Addons](#addons)** · **[Docs](./docs/)**

---

## Quickstart

```bash
# One-time: clone Bench somewhere stable
git clone git@github.com:PDX-Apps/bench.git ~/path/to/bench

# Each project: run init from the project root
cd ~/my-laravel-project
~/path/to/bench/bin/bench init
```

`init` will:

- Auto-detect Laravel / PHP / Vue / React versions (with interactive monorepo scan when needed)
- Offer to scaffold a starter `CLAUDE.md` documenting your project layout
- Install the plugin into `.claude/plugins/bench/`
- Offer to register it in `.claude/settings.json` (or print manual `/plugin` commands)

Open Claude Code in the project. Try `/help` to see what's available. Suggested first commands to try:

```
/bench-onboard                            # AI scans your project + tailors Bench to it
/api create endpoint to list user sessions
/vue-component create SessionCard
/orchestrate implement <feature-description>
```

That's it. Day two onward, you mostly use slash commands inside Claude Code. The CLI only comes back for occasional rebuilds or addon management.

### Onboarding (AI-driven, optional)

Bench ships a bundled `bench-onboard` addon that adds slash commands for adapting Bench to *your* project:

| Command | Purpose |
|---|---|
| `/bench-onboard` | First-time setup: scan the codebase, generate CLAUDE.md, propose pattern overrides + custom skills |
| `/bench-update-claudemd` | Refresh CLAUDE.md from the current codebase |
| `/bench-add-pattern {domain}` | Capture a project-specific convention as a pattern override |
| `/bench-add-skill {name} "..."` | Scaffold a custom slash command + paired worker agent |
| `/bench-add-domain {name}` | Onboard a single new module/feature area |
| `/bench-audit` | Check whether CLAUDE.md and `.bench/` overrides have drifted |

All support `--depth=shallow|standard|deep`. Skip the bundle with `bench init --no-onboard` if you'd rather configure CLAUDE.md and `.bench/` by hand.

---

## How it works

Three concepts:

| Concept | What it is | Where it lives |
|---|---|---|
| **Patterns** | Markdown docs describing how to write a given artifact (a Laravel controller, a Vue component, a Pinia store). The shared knowledge base. | `patterns/` (source) → resolved into `patterns-built/` per project |
| **Skills** | Slash commands like `/api`, `/vue-component`. Each parses your request, inspects your project, and delegates to a worker agent with structured context. | `skills/` |
| **Agents** | Subagents that do the actual code generation. Read only the relevant patterns, scaffold the artifact, return a summary. Isolated context. | `agents/` |

The main Claude Code conversation stays at the **feature level** — you describe what you want, agents handle the implementation details, pattern files stay out of your context window.

### Adaptive — not opinionated

Every Bench agent reads your project's `CLAUDE.md` before generating. If it says "Laravel lives at `apps/cloud/`, tests use Pest, shared Vue components go in `packages/ui/`" — agents follow that, not the plugin's defaults.

For deeper customization (project-specific skills, agents, or pattern overrides), drop them in `./.bench/` and they're auto-loaded. See [docs/addons.md](./docs/addons.md).

---

## Configuring per project

Three layers of customization, in increasing scope:

### 1. CLAUDE.md (your project's memory)

Free-form markdown at your project root. Agents read it on every invocation. Document:

- Monorepo layout (where Laravel + frontend apps live)
- Test framework choice (Pest vs PHPUnit)
- UI library (Quasar, MUI, Radix, none)
- Naming conventions, locale set, anything that differs from defaults

`bench init` offers to scaffold a starter from your detected layout.

### 2. `.bench/` — project-local extensions

Skills / agents / pattern overrides that apply only to *this* project. Same directory shape as the core plugin. Auto-discovered. Merges in on top of core patterns. See [docs/addons.md](./docs/addons.md) for the format.

```
my-project/
└── .bench/
    ├── .bench-addon.yaml             # manifest
    ├── patterns/frontend/vue/...     # override a specific pattern
    ├── skills/my-custom-skill/       # add a new slash command
    └── agents/my-custom-agent.md     # add the worker behind it
```

### 3. Reusable addons (multi-project)

Frameworks or conventions you want to share across multiple projects. Same format as `.bench/`, but lives in its own repo. Install per-project:

```bash
./.claude/plugins/bench/bin/bench addon add ~/path/to/MyAddon
```

Persisted across rebuilds. See [Addons](#addons) below.

---

## Addons

Reusable framework-specific pattern packs that extend core. Bench's core stays generic (Laravel + Vue/React); framework-specific behaviors (UI libraries, opinionated frameworks layered on Laravel/Vue) ship as addons.

Examples of what an addon would contribute:

- Component patterns for a specific UI library (Quasar, Vuetify, Radix, MUI, shadcn/ui)
- Conventions for an opinionated Laravel framework (Filament, Nova, Inertia, Livewire)
- Patterns for a Vue/React meta-framework (Nuxt, Next.js)
- Project-team-internal conventions you want to share across multiple projects you maintain

Same directory shape as `.bench/` (project-local extensions), plus a `.bench-addon.yaml` manifest. Install per-project:

```bash
./.claude/plugins/bench/bin/bench addon add ~/path/to/MyAddon
```

Persisted across rebuilds. Build your own: see [docs/addons.md](./docs/addons.md).

---

## CLI reference

Daily Bench usage is via Claude Code slash commands. The CLI is for setup + occasional maintenance:

```bash
~/path/to/bench/bin/bench init                  # one-time per project
./.claude/plugins/bench/bin/bench status        # what's installed
./.claude/plugins/bench/bin/bench rebuild       # re-mirror source (after git pull on bench)
./.claude/plugins/bench/bin/bench addon list    # see registered addons
./.claude/plugins/bench/bin/bench addon add <path>
./.claude/plugins/bench/bin/bench addon remove <name-or-path>
```

Tired of typing the path? Two options:

```bash
# (a) Shell alias — add to ~/.zshrc:
alias bench='./.claude/plugins/bench/bin/bench'

# (b) Global symlink (one time, no sudo, ~/.local/bin):
~/path/to/bench/scripts/install-cli.sh
```

Both optional. Fully-qualified path always works.

`bench init` flags:

| Flag | Purpose |
|---|---|
| `--register` / `--no-register` | Auto-write to `.claude/settings.json` or skip (manual `/plugin install` from CC) |
| `--symlink` | Plugin-dev mode — symlink source into project (internals visible). Default is copy. |
| `--addon=PATH` | Load an addon (repeatable, persisted) |
| `--laravel=N` / `--php=N` / `--frontend=vue\|react\|none` / `--vue=N` | Override version detection |
| `--no-addon` | Skip auto-discovery of `./.bench/` (debugging) |

---

## What's in the box

```
patterns/
├── laravel/                  # 50 patterns: controllers, models, actions, services,
│                             # migrations, modules, DTOs, jobs, listeners, policies,
│                             # AI SDK (laravel/ai), Pest tests, ...
└── frontend/
    ├── vue/                  # 20 patterns: components, pages, layouts, routes,
    │                         # Pinia stores, services, models, Zod validators,
    │                         # vue-i18n, composables, Vitest, Playwright
    └── react/                # 20 patterns: React 18 + TS + React Router v6 +
                              # Zustand + TanStack Query + react-hook-form +
                              # react-i18next + @testing-library/react
+ version overrides for Laravel 12 / PHP 8.4

skills/                       # ~50 slash commands (filtered by chosen frontend)
agents/                       # ~50-70 worker agents (filtered by chosen frontend)
```

Bench scopes its skills/agents to the frontend you chose — a Vue project doesn't see `/react-*` commands and vice versa.

---

## Roadmap

- **Multi-CLI**: Bench is Claude-Code-shaped today (skills, agents, `Task` tool semantics). Patterns are CLI-agnostic. The source structure leaves room for `targets/{gemini,codex,cursor}/` adapters when there's demand. Not built yet.
- **Public addons**: addon authoring is supported today; community addons for popular Laravel/Vue/React ecosystems (Filament, Inertia, Nuxt, Vuetify, Radix, etc.) would land here as they're built.
- **React patterns at parity with Vue**: pattern bodies are written; haven't been battle-tested against a real React project yet.
- **One-line install**: today you clone Bench then run `init`. Once there's a public release channel (GitHub Releases / brew tap / npm), a single `curl | bash` should suffice.

---

## Architecture

Deeper read for contributors and curious users:

- [docs/architecture.md](./docs/architecture.md) — the source-of-truth design doc: skills-vs-agents-vs-patterns, version overrides, addon mechanism, build pipeline
- [docs/addons.md](./docs/addons.md) — addon authoring spec

---

## Project structure (Bench itself)

```
bench/
├── bin/bench                      # CLI dispatcher
├── scripts/
│   ├── init-project.sh            # bench init
│   ├── install.sh                 # mirror source → install, substitute, build
│   ├── build-patterns.sh          # resolve base + overrides + addons → patterns-built/
│   ├── install-cli.sh             # optional global symlink helper
│   └── validate-overrides.sh      # check version-override hashes against base
├── patterns/
│   ├── laravel/{base,overrides}/
│   └── frontend/{vue,react}/{base,overrides}/
├── skills/                        # Claude Code skills
├── agents/                        # Claude Code agents
├── .claude-plugin/
│   ├── plugin.json                # CC plugin manifest
│   └── marketplace.json           # CC marketplace manifest
├── docs/
├── docs/architecture.md
└── README.md
```

Source has all the machinery. Project installs (`.claude/plugins/bench/`) get only runtime artifacts — `agents/`, `skills/`, `patterns-built/`, `bin/bench`, `.claude-plugin/`. Internals stay at source.

---

## License

MIT. See LICENSE.

## Author

[PDX Apps](https://pdxapps.com) — Irv Gomez.
