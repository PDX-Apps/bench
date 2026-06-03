# Changelog

All notable changes to Bench. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

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
