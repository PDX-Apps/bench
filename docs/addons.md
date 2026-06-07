# Bench — Addons

Addons let third parties (or your own projects) contribute additional patterns, skills, and agents on top of core Bench. The mechanism is the same whether you're shipping a reusable addon, carrying project-specific extensions, or using one of the [bundled addons](#bundled-addons-shipped-in-the-repo) under `addons/`.

For *how to write* one: see [Authoring an addon](#authoring-an-addon). For the architecture an addon plugs into: see [architecture.md](./architecture.md).

---

**Contents:** [Anatomy](#anatomy-of-an-addon) · [Manifest](#manifest-bench-addonyaml) · [How addons load](#how-addons-load) · [Precedence](#precedence-summary) · [Loading methods](#loading-methods) · [Bundled addons](#bundled-addons-shipped-in-the-repo) · [Persistence + management](#persistence--management) · [Authoring](#authoring-an-addon) · [Roadmap](#roadmap)

---

## Anatomy of an addon

An addon is a directory with the same shape as core:

```
my-addon/
├── .bench-addon.yaml             # required — declares the addon
├── patterns/                     # optional — merged into core's patterns-built/ output
│   ├── laravel/                  #   put files at any path under patterns/ —
│   │   ├── controllers/…         #   they land at patterns-built/{same-path}
│   │   └── ai/…
│   └── frontend/
│       └── vue/…
├── skills/                       # optional — installed alongside core's skills/
│   └── my-skill/
│       └── SKILL.md
└── agents/                       # optional — installed alongside core's agents/
    └── my-agent.md
```

Skills and agents inside the addon can use the same `<PLUGIN_ROOT>` placeholder that core uses to reference paths in the install. Install-time substitution rewrites it to the actual install path.

Optionally include a `README.md` at the addon root with usage instructions — the [bundled addons](#bundled-addons-shipped-in-the-repo) do this.

---

## Manifest: `.bench-addon.yaml`

Minimal — the directory layout *is* the contract. The manifest just declares the addon's identity.

```yaml
name: my-framework-kit            # required — unique identifier (kebab-case)
version: 0.1.0                    # required — semver
description: |                    # required — one-line summary
  Patterns + skills + agents for the MyFramework stack on top of
  Laravel + Vue: custom store wrappers, UI library conventions,
  test helpers.

depends_on:                       # optional
  bench: ">=0.8.0"                 #   minimum core version
  addons: [bench-ci, bench-playwright]   # require other addons (auto-installed)

# Optional metadata (informational only — not enforced by the loader)
homepage: https://github.com/your-org/my-framework-kit
author: Your Name
license: MIT
```

No declarative contribution lists — what the addon contributes is determined by what's in its `patterns/`, `skills/`, `agents/` directories.

### Addon dependencies (`depends_on.addons`)

An addon can **require other addons** instead of duplicating their content — e.g. `bench-quality` declares `depends_on.addons: [bench-ci, bench-playwright]` and delegates to their `ci` / `e2e` agents. At install/rebuild, the loader **resolves each dependency** (by bundled directory name *or* by manifest `name:`), pulls it in **transitively** (deps load before dependents), and de-dups. A missing dependency warns loudly. Dependencies are resolved at build time, not persisted — they follow the dependent automatically. For composition to work, the depended-on functionality should be exposed as a **Task-delegatable agent** (not only a skill).

---

## How addons load

`bench init` (and `bench rebuild`) processes addons in this order:

1. **Core mirror + build pass** — mirrors core's `skills/` + `agents/` (flattened from source groups) and resolves `patterns/` (base + version overrides) into `patterns-built/`.
2. **For each registered addon** (in declaration order):
   - Walk addon's `patterns/**/*.md` and copy each file into the matching `patterns-built/...` path. **Addon wins** on collision with the core-built file.
   - Copy addon's `skills/*/` flat into the installed plugin's `skills/`. Addon wins on same-name. Backups of any overwritten core files are kept so removal restores them.
   - Copy addon's `agents/*.md` flat into the installed plugin's `agents/`. Addon wins on same-name. Backups kept.
3. **Path substitution pass** — `<PLUGIN_ROOT>` placeholders in all skill + agent files (core + addon) get rewritten to the actual install path.

The output is a single `.claude/plugins/bench/` that Claude Code auto-discovers. From CC's perspective there's one plugin; addons are transparent.

### Precedence summary

When two sources provide the same file path, the later wins:

```
core base
  ↓ overridden by
core version overrides (active axis only)
  ↓ overridden by
addon 1 patterns/
  ↓ overridden by
addon 2 patterns/   (later --addon= flag wins)
```

Same rule for skills + agents: later addon wins, addons win over core.

---

## Loading methods

### 1. By path

```bash
bench init --addon=/path/to/your-addon
bench addon add /path/to/your-addon
```

Use this for reusable addons you've cloned locally.

### 2. Bundled (by short name)

The `addons/` directory at the bench source ships with built-in addons. Add by bare name — `bench addon add` resolves it via `.install-source` automatically:

```bash
bench addon add laravel-boost
bench addon add onboard
```

See [Bundled addons](#bundled-addons-shipped-in-the-repo) below for what's available.

### 3. Auto-discovered project-local extensions

If `./.bench/` exists at the project root with a valid `.bench-addon.yaml`, it's loaded automatically — no `--addon=` flag needed. Use this for project-specific patterns/skills/agents that live alongside your code:

```
my-project/
├── composer.json
├── .bench/
│   ├── .bench-addon.yaml      (name: my-project-extensions)
│   ├── patterns/…
│   ├── skills/…
│   └── agents/…
└── src/
```

The bundled [`bench-manager`](../addons/bench-manager/README.md) addon writes here (via `/bench-override` and `/bench-slice`) when capturing project-local overrides + custom slices.

### 4. Multiple addons

```bash
bench init \
  --addon=onboard \
  --addon=laravel-boost \
  --addon=~/path/to/internal/my-team-conventions
```

Order matters — later addons win conflicts.

---

## Bundled addons (shipped in the repo)

Live under `addons/` at the bench source. Add by short name:

| Short name | What it does | Loaded by default? | Docs |
|---|---|---|---|
| `bench-manager` | The `/bench-*` project-tailoring toolkit — `/bench-init`, `/bench-override`, `/bench-slice`, `/bench-list`, `/bench-show`, `/bench-status` + the authoring agents behind them | Yes — opt out with `bench init --no-onboard` | [addons/bench-manager/README.md](../addons/bench-manager/README.md) |
| `laravel-boost` | Awareness of [laravel/boost](https://github.com/laravel/boost) MCP + `/boost-install` skill that walks through composer install + `boost:install` + MCP registration with permission prompts | Opt-in: `bench addon add laravel-boost` | [addons/laravel-boost/README.md](../addons/laravel-boost/README.md) |

The bundled addons are themselves a worked example of the addon spec — read their source for a reference implementation.

---

## Persistence + management

Addons passed via `--addon=` (or added via `bench addon add`) are recorded in `.install-addons-config` inside the install. `bench rebuild` re-applies the same set automatically, so you don't have to re-specify them every time.

```bash
bench addon list                       # show registered addons
bench addon add PATH-OR-NAME           # add (path or bundled short name) and rebuild
bench addon remove NAME-OR-PATH        # matches by manifest name or path; rebuilds
```

The auto-discovered `./.bench/` extension is NOT persisted — it's re-discovered on every rebuild because it travels with the project repo.

---

## Authoring an addon

1. Create a directory with `.bench-addon.yaml` declaring `name`, `version`, `description`.
2. Mirror core's `patterns/` layout for any pattern files you want to add or override (e.g., `patterns/laravel/controllers/CTRL-008-my-custom.md`).
3. Add skills under `skills/<skill-name>/SKILL.md` and agents under `agents/<agent-name>.md`.
4. Use `<PLUGIN_ROOT>` in any absolute path references inside skill / agent files — install-time substitution handles the rest.
5. Test against a real project: `bench init --addon=/path/to/your/addon`.
6. Optionally add a `README.md` at the addon root with usage docs.

### Tips

- **Don't fork files unnecessarily.** If core's pattern is fine as-is, leave it; only contribute files that meaningfully diverge.
- **Match core's pattern frontmatter format** if you want the overrides validation tool (`scripts/validate-overrides.sh`) to work.
- **One addon, one purpose.** Don't bundle unrelated additions — split into separate addons.
- **Declare `depends_on` honestly.** Specify the minimum core version your addon was authored against.
- **Pair skills with worker agents.** A skill that does its own code generation (instead of delegating to a worker) bloats the main conversation context — see [architecture.md](./architecture.md) for the skills-vs-agents split.

---

## Roadmap

Not in v1 yet:

- Git-URL addon loading (`bench addon add git+https://...`)
- Addon registry / `bench addon search`
- Per-addon version overrides (e.g., addon contributes a vue-2 fallback)
- Addon publishing / signing / verification
