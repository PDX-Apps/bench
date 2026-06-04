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

| Command | When to use |
|---|---|
| `/bench-onboard` | First-time setup. Walks the full flow: CLAUDE.md scaffold → propose pattern overrides → propose custom skills |
| `/bench-update-claudemd` | Refresh CLAUDE.md from the current codebase (diff mode by default; `--force` to overwrite) |
| `/bench-add-pattern {domain}` | Capture one convention (e.g., `controller`, `pinia-store`, `vue-component`) as a project-local pattern override |
| `/bench-add-skill {name} "{desc}"` | Scaffold a new slash command + its paired worker agent for a project-specific workflow |
| `/bench-add-agent {name} "{desc}"` | Scaffold a standalone worker agent (rare — most agents pair with a skill) |
| `/bench-add-domain {name}` | Onboard one new module/feature area without rescanning the whole project |
| `/bench-audit` | Check whether CLAUDE.md and `.bench/` overrides have drifted from the codebase |

All commands support `--depth=shallow|standard|deep`.

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
| `pattern-researcher` | A project-local pattern override under `./.bench/patterns/{group}/{name}.md` |
| `skill-researcher` | A project-local slash command at `./.bench/skills/{name}/SKILL.md` (then delegates to agent-researcher for the worker) |
| `agent-researcher` | A worker agent at `./.bench/agents/{name}.md` (typically `{skill-name}-worker`) |

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
