# Bench

> Teach AI coding assistants the conventions of *your* Laravel + Vue/React project — once, then they generate code that fits.

**Status: beta (v0.8.x).** Functional end-to-end, not battle-tested across many projects yet. API soft-stable until v1.0.0. See [CHANGELOG.md](./CHANGELOG.md) for what's shipped and the gating criteria for stable.

Most AI coding assistants generate generic-best-practices code. That works for greenfield, but real projects have their own monorepo layouts, framework versions, test frameworks, UI libraries, file conventions, naming rules. Bench is a pluggable kit of slash commands + worker agents + framework knowledge that adapts to *your* project, so AI-generated code lands in the right place, in the right shape, the first time.

Built for [Claude Code](https://docs.claude.com/en/docs/claude-code) today. Designed to extend to other AI CLIs.

---

**Contents:** [Quickstart](#quickstart) · [How it works](#how-it-works) · [What's in the box](#whats-in-the-box) · [Bundled addons](#bundled-addons) · [Per-project configuration](#per-project-configuration) · [CLI reference](#cli-reference) · [Roadmap](#roadmap) · [Docs](#docs) · [License](#license)

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

- Auto-detect Laravel / PHP / Vue / React versions (with an interactive monorepo scan when there's no root `composer.json`/`package.json`)
- Offer to scaffold a starter `CLAUDE.md` documenting your project layout
- Install the plugin into `.claude/plugins/bench/`
- Offer to register it in `.claude/settings.json` (or print the manual `/plugin` commands)
- Auto-load the bundled [`onboard`](./addons/onboard/README.md) addon for AI-driven project onboarding (opt out with `--no-onboard`)

Open Claude Code in the project. Try `/help` to see what's available. Suggested first commands:

```
/bench-onboard                            # AI scans your project + tailors Bench to it
/api create endpoint to list user sessions
/vue-component create SessionCard
/orchestrate implement <feature-description>
```

That's it. Day two onward you mostly use slash commands inside Claude Code. The CLI comes back only for occasional rebuilds or addon management.

---

## How it works

Three concepts:

| Concept | What it is | Where it lives |
|---|---|---|
| **Patterns** | Markdown docs describing how to write a given artifact (a Laravel controller, a Vue component, a Pinia store). The shared knowledge base. | `patterns/` at source → resolved into `patterns-built/` per project |
| **Skills** | Slash commands like `/api`, `/vue-component`. Each parses your request, inspects your project, resolves any ambiguity, then delegates to a worker agent with structured context. | `skills/` |
| **Agents** | Subagents that do the actual code generation. Read only the relevant patterns, scaffold the artifact, return a summary. Isolated context. | `agents/` |

The main Claude Code conversation stays at the **feature level** — you describe what you want, agents handle implementation details, pattern files stay out of your context window.

**Adaptive — not opinionated.** Every Bench agent reads your project's `CLAUDE.md` before generating. If it says "Laravel lives at `apps/cloud/`, tests use Pest, shared Vue components go in `packages/ui/`" — agents follow that, not the plugin's defaults.

For the full internal design (skill anatomy, pattern resolution, build pipeline, source/install split), see [docs/architecture.md](./docs/architecture.md).

---

## What's in the box

**Patterns** (90 base + 9 version overrides)

- 50 Laravel patterns: controllers, models, actions, services, migrations, modules, DTOs, jobs, listeners, policies, AI SDK (`laravel/ai`), tests
- 20 Vue patterns: components, pages, layouts, routes, Pinia stores, services, models, Zod validators, vue-i18n, composables, Vitest
- 20 React patterns: React 18 + TS + React Router v6 + Zustand + TanStack Query + react-hook-form + react-i18next + @testing-library/react
- 9 version overrides for Laravel 12 / PHP 8.4 fallbacks (base targets Laravel 13 / PHP 8.5)

**Skills** (60 source, filtered at install)

- 32 Laravel skills (`/api`, `/controller`, `/model`, `/migration`, `/event`, `/job`, `/policy`, `/ai-agent`, `/feature-test`, …)
- 12 Vue skills (`/vue-component`, `/vue-page`, `/vue-store`, `/vue-ui` coordinator, …)
- 12 React skills (`/react-component`, `/react-page`, `/react-store`, `/react-ui` coordinator, …)
- 4 meta skills (`/orchestrate`, `/help`, `/ci`, `/mcp-tools`)

**Agents** (71 source, filtered at install)

- 37 Laravel workers + 17 Vue workers + 17 React workers
- Workflow agents (`exec-spec`, `bug-fix`, `refactor`, `new-module`) for full-stack work via `/orchestrate`

The install prunes the inactive frontend automatically — a Vue project doesn't see `/react-*` and vice versa.

---

## Bundled addons

Ship in this repo under `addons/`. Add by short name; bundled-name resolution is built into `bench addon add`:

| Addon | What it gives you | Loaded by default? | Docs |
|---|---|---|---|
| [`onboard`](./addons/onboard/README.md) | AI-driven project onboarding: 7 slash commands (`/bench-onboard`, `/bench-update-claudemd`, `/bench-add-pattern`, `/bench-add-skill`, `/bench-add-agent`, `/bench-add-domain`, `/bench-audit`) + 4 researcher agents that scan your codebase and write `CLAUDE.md` + `.bench/` overrides | Yes — opt out with `bench init --no-onboard` | [addons/onboard/README.md](./addons/onboard/README.md) |
| [`laravel-boost`](./addons/laravel-boost/README.md) | Awareness of [laravel/boost](https://github.com/laravel/boost) MCP tools + `/boost-install` skill that walks through composer install, `php artisan boost:install`, and MCP registration with permission prompts | Opt-in: `bench addon add laravel-boost` | [addons/laravel-boost/README.md](./addons/laravel-boost/README.md) |

Want to write your own? See [docs/addons.md](./docs/addons.md) for the authoring spec.

---

## Per-project configuration

Three layers, in increasing scope:

1. **`CLAUDE.md`** at your project root. Every Bench agent reads it. Document your monorepo layout, test framework choice, UI library, naming rules — anything that overrides defaults. `bench init` offers to scaffold one, or run `/bench-onboard` to have AI generate it from a codebase scan.

2. **`.bench/`** at your project root. Auto-discovered project-local extensions: pattern overrides, custom slash commands, custom worker agents. Same shape as core. Travels with your project repo. Generated automatically by `/bench-add-pattern` / `/bench-add-skill` from the onboard addon.

3. **Reusable addons** for conventions you want to share across multiple projects. Same shape as `.bench/` plus a `.bench-addon.yaml`. Install per-project with `bench addon add /path/to/addon` (or bare short name for bundled ones). See [docs/addons.md](./docs/addons.md).

---

## CLI reference

Daily usage is slash commands inside Claude Code. The CLI is for setup + occasional maintenance:

```bash
bench init                      # one-time per project
bench status                    # what's installed in the current project
bench rebuild                   # re-mirror source + rebuild patterns (after pulling bench updates)
bench addon list                # registered addons for the current project
bench addon add NAME-OR-PATH    # add an addon (bare name resolves bundled; full path also works)
bench addon remove NAME-OR-PATH # remove an addon and rebuild
```

For these to work as bare `bench` (not `~/path/to/bench/bin/bench`):

```bash
# (a) Shell alias — add to ~/.zshrc:
alias bench='./.claude/plugins/bench/bin/bench'

# (b) Global symlink (one time, no sudo, drops to ~/.local/bin):
~/path/to/bench/scripts/install-cli.sh
```

Both optional — the fully-qualified path always works.

`bench init` flags:

| Flag | Purpose |
|---|---|
| `--register` / `--no-register` | Auto-write to `.claude/settings.json` or print manual `/plugin install` path |
| `--symlink` | Plugin-dev mode — symlink source into project (internals visible). Default is copy. |
| `--addon=PATH` | Load an addon (repeatable, persisted) |
| `--no-onboard` | Skip the bundled `onboard` addon |
| `--laravel=N` / `--php=N` / `--frontend=vue\|react\|none` / `--vue=N` | Override version detection |
| `--no-addon` | Skip auto-discovery of `./.bench/` (debugging) |

---

## Roadmap

- **Public addons**: addon authoring is supported today; community addons for popular ecosystems (Filament, Inertia, Nuxt, Vuetify, Radix, shadcn/ui) would land as separate repos.
- **React parity**: React patterns are written but haven't been battle-tested against a real React project yet. Vue side has been tested against a complex monorepo.
- **Multi-CLI**: Bench is Claude-Code-shaped today (skills, agents, `Task` tool semantics). Patterns are CLI-agnostic. The source structure leaves room for `targets/{gemini,codex,cursor}/` adapters when there's demand.
- **One-line install**: today you clone Bench then run `init`. Once there's a public release channel (GitHub Releases / brew tap / npm), a single `curl | bash` should suffice.

Full v1.0 gating criteria + post-v1 backlog: [CHANGELOG.md](./CHANGELOG.md).

---

## Docs

- [docs/architecture.md](./docs/architecture.md) — how Bench is built internally: skills vs agents vs patterns, pattern resolution, source/install split, build pipeline, frontend filtering
- [docs/addons.md](./docs/addons.md) — addon authoring spec: anatomy, manifest, load order, precedence, bundled addons, persistence
- [addons/onboard/README.md](./addons/onboard/README.md) — AI-driven onboarding addon
- [addons/laravel-boost/README.md](./addons/laravel-boost/README.md) — laravel/boost MCP integration addon
- [CHANGELOG.md](./CHANGELOG.md) — release notes + v1.0 gating criteria

---

## License

MIT. See [LICENSE](./LICENSE).

## Author

[PDX Apps](https://pdxapps.com) — Irv Gomez.
