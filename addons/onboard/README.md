# bench-onboard

AI-driven project onboarding for Bench. Scans your codebase, optionally interviews you, and generates project-specific `CLAUDE.md` + `.bench/` overrides so AI agents understand *your* project from day one.

**Status:** bundled with Bench, auto-loaded by `bench init`. Opt out with `bench init --no-onboard`.

---

**Contents:** [What it does](#what-it-does) · [Commands](#commands) · [Depth modes](#depth-modes) · [How it works internally](#how-it-works-internally) · [Files written](#files-written)

---

## What it does

Most projects have conventions that aren't visible in any one file: which test framework to use, where shared components live, what domain language the team uses, what `Session` actually means. The bench-onboard addon's slash commands inspect your codebase across multiple layers (manifests → structure → samples → prose → git activity → user interview when needed) and produce:

- A starter `CLAUDE.md` capturing those conventions
- Optional pattern overrides under `./.bench/patterns/` for places where your project diverges from Bench defaults
- Optional custom slash commands + paired worker agents under `./.bench/skills/` + `./.bench/agents/` for workflows specific to your project

Everything is opt-in per step — the researcher agents present findings and proposed files, you approve before anything gets written.

---

## Commands

### Discovery (read-only)

| Command | When to use |
|---|---|
| `/bench-list [patterns\|skills\|agents]` | See what's available — bundled defaults and project-local overrides. Pass no arg for a summary across all three. |
| `/bench-show <type> <name>` | View the full body of a specific pattern, skill, or agent — typically before deciding to override it. |
| `/bench-status` | Synthesized health check — versions, addons, CLAUDE.md presence, drift detection, suggested next steps. Friendlier wrapper around `bench status`. |

### Add or override

These commands handle both **adding new** and **overriding bundled defaults**. Each auto-detects intent: if you name a bundled artifact and describe a change, it forks; if you describe a project-specific workflow that doesn't exist yet, it adds new. If ambiguous, the researcher will ask.

| Command | When to use |
|---|---|
| `/bench-add-pattern {domain}` | Add OR fork a Bench pattern. "Override the controller pattern to use cache() instead of DI" → FORK. "We extend BaseController in this project" → CAPTURE. |
| `/bench-add-skill {name} "{desc}"` | Add OR fork a slash command. "Scaffold a /saga command" → NEW. "Make /api skip generating tests" → FORK. |
| `/bench-add-agent {name} "{desc}"` | Add OR fork a worker agent. Standalone analyzers → NEW. "Override the controller agent's verification step" → FORK. (Most users want `/bench-add-skill` instead, which generates both skill + worker.) |

### Lifecycle

| Command | When to use |
|---|---|
| `/bench-onboard` | First-time setup. Walks the full flow: CLAUDE.md scaffold → propose pattern overrides → propose custom skills |
| `/bench-update-claudemd` | Refresh CLAUDE.md from the current codebase (diff mode by default; `--force` to overwrite) |
| `/bench-add-domain {name}` | Onboard one new module/feature area without rescanning the whole project |
| `/bench-audit` | Check whether CLAUDE.md and `.bench/` overrides have drifted from the codebase |

All commands support `--depth=shallow|standard|deep`.

### Overriding by talking to Claude

You don't need to remember the exact command. Just describe what you want different:

- *"I prefer global helpers like cache() over DI in services"* — Claude routes to `/bench-add-pattern` in FORK mode, reads the bundled service pattern, modifies it, writes the override under `./.bench/patterns/...`, rebuilds.
- *"Make /api skip generating tests"* — Claude routes to `/bench-add-skill api` in FORK mode, reads the bundled SKILL.md, modifies the relevant step, writes the override.
- *"Show me what the controller pattern looks like"* — Claude routes to `/bench-show pattern controller`.
- *"What skills come bundled?"* — Claude routes to `/bench-list skills`.

The trigger phrases in each skill's description handle the routing automatically.

---

## Depth modes

The depth budget controls how many files the researcher agents read and how many interview questions they ask. Pass it as `--depth=N` on any command.

| Mode | File-read budget | Interview questions max | Use when |
|---|---|---|---|
| `shallow` | ≤5 | 0–2 | Project has a clear description; quick scan needed |
| `standard` (default) | ≤25 | up to 5 | Sane default — enough signal at modest cost |
| `deep` | ≤100 | up to 15 | First-time onboarding of a complex monorepo; you want thoroughness |

The chosen budget is printed at the start of any scan: *"Scanning up to 25 files (--depth=standard). Use --depth=deep for more thoroughness or --depth=shallow to skip."*

---

## How it works internally

The addon ships **4 specialist researcher agents** that share a single [layered scan methodology](./patterns/onboarding/METHODOLOGY-layered-scan.md):

| Researcher | Produces |
|---|---|
| `claudemd-researcher` | Project's root `CLAUDE.md` (or a diff against an existing one) |
| `pattern-researcher` | A project-local pattern at `./.bench/patterns/{group}/{name}.md`. Modes: **CAPTURE** (scan project, write convention) or **FORK** (read bundled, modify it). |
| `skill-researcher` | A project-local skill at `./.bench/skills/{name}/SKILL.md`. Modes: **NEW** (design from scratch) or **FORK** (read bundled SKILL.md, modify). Delegates to `agent-researcher` for the worker. |
| `agent-researcher` | A worker agent at `./.bench/agents/{name}.md`. Modes: **NEW** (design from scratch) or **FORK** (read bundled, modify). |

The `/bench-list` and `/bench-show` discovery skills are skill-only (no worker) — they just read the install + project state and report.

Each researcher reads the [methodology](./patterns/onboarding/METHODOLOGY-layered-scan.md) plus its own artifact-specific lens (`RESEARCH-claudemd.md`, `RESEARCH-patterns.md`, `RESEARCH-skills.md`, `RESEARCH-agents.md`). The 7 slash commands are thin orchestrators — they parse the user's request, delegate to the right researcher, and surface the findings report + proposed files for user approval before anything gets written.

The methodology has 6 layers, applied top-to-bottom and stopping as soon as the question's answered:

1. **Manifests** (`composer.json`, `package.json`, lint configs, …) — cheap, high signal
2. **Project shape** — single `find` to map directory layout
3. **Representative sampling** — read 2–3 of each artifact type, validate with grep
4. **Prose docs** — README, CONTRIBUTING, ADRs, existing CLAUDE.md
5. **Git activity** — recent churn reveals which areas are active
6. **Interview** — ask only what code can't reveal

---

## Files written

Everything the addon writes lands inside your project:

- `{project_root}/CLAUDE.md` — project memory (every Bench agent reads it before generating)
- `{project_root}/.bench/patterns/{group}/{name}.md` — pattern overrides
- `{project_root}/.bench/skills/{name}/SKILL.md` — custom slash commands
- `{project_root}/.bench/agents/{name}.md` — custom worker agents

`./.bench/` is automatically picked up by `bench init` / `bench rebuild` — no separate registration needed. After the addon writes anything under `.bench/`, it triggers a rebuild so the new files are materialized into the install.

---

## Opting out

If you'd rather configure `CLAUDE.md` and `.bench/` by hand, install Bench without this addon:

```bash
bench init --no-onboard
```

You can also remove it from an existing install:

```bash
bench addon remove bench-onboard
```

Or add it back later:

```bash
bench addon add onboard
```
