# Bench — Addon Plugins

Addons let third parties (or your own projects) contribute additional patterns, skills, and agents on top of the core Bench plugin. The mechanism is the same whether you're shipping a reusable addon (e.g., ``) or carrying project-specific extensions.

---

## Anatomy of an addon

An addon is a directory with the same shape as core:

```
my-addon/
├── .bench-addon.yaml          # required — declares the addon
├── patterns/                    # optional — merged into core's patterns-built/ output
│   ├── laravel/
│   │   ├── base/                # add or replace files in core's laravel base
│   │   └── overrides/
│   │       └── laravel-12/      # add or replace files in core's L12 overrides
│   └── frontend/
│       └── vue/
│           ├── base/
│           └── overrides/
├── skills/                      # optional — installed alongside core's skills/
│   └── my-skill/
│       └── SKILL.md
└── agents/                      # optional — installed alongside core's agents/
    └── my-agent.md
```

Skills and agents inside the addon use the same `<PLUGIN_ROOT>` placeholder that core uses. Install-time substitution rewrites it to the actual install path.

---

## Manifest: `.bench-addon.yaml`

Minimal — the directory layout IS the contract.

```yaml
name: my-framework-kit            # required — unique identifier (kebab-case)
version: 0.1.0                    # required — semver
description: |                    # required — one-line summary
  Patterns + skills + agents for the MyFramework stack on top of
  Laravel + Vue: custom store wrappers, UI library conventions,
  test helpers.

depends_on:                       # optional — fail install if core version mismatches
  bench: ">=0.8.0"

# Optional metadata (informational only — not enforced by the loader)
homepage: https://github.com/your-org/my-framework-kit
author: Your Name
license: MIT
```

That's it. No declarative contribution lists — what the addon contributes is determined by what's in its `patterns/`, `skills/`, `agents/` directories.

---

## How addons load

`bench init` (or `bench rebuild`) builds in this order:

1. **Core build pass** — `build-patterns.sh` resolves core's base + version overrides into `patterns-built/laravel/` and `patterns-built/frontend/{vue,react}/`.
2. **For each registered addon** (in declaration order):
   - Walk addon's `patterns/**/*.md` and copy each file into the matching `patterns-built/...` path. **Addon wins** on collision with the core-built file.
   - Copy addon's `skills/*` into the installed plugin's `skills/` (addon wins on same-name).
   - Copy addon's `agents/*.md` into the installed plugin's `agents/` (addon wins on same-name).
3. **Path substitution pass** — `<PLUGIN_ROOT>` placeholders in all skill + agent files (core + addon) get rewritten to the actual install path.

The output is a single `.claude/plugins/bench/` that Claude Code auto-discovers. From CC's perspective there's one plugin; addons are transparent.

### Precedence summary

When two sources provide the same file path, the later wins:

```
core base
  ↓ overridden by
core overrides (active version axis only)
  ↓ overridden by
addon 1 patterns/
  ↓ overridden by
addon 2 patterns/   (later --addon= flag wins)
```

For skills/agents: same rule — later addon wins, addons win over core.

---

## Three ways to load an addon

### 1. By path

```bash
bench init --addon=~/Workspace/pdxapps.com/repos/
```

Use this for reusable addons you've cloned locally.

### 2. Auto-discovered project-local extensions

If `./.bench/` exists at the project root with a valid `.bench-addon.yaml`, it's loaded automatically. Use this for project-specific patterns/skills/agents that live alongside your code.

```
my-project/
├── composer.json
├── .bench/
│   ├── .bench-addon.yaml      (name: my-project-extensions)
│   ├── patterns/
│   ├── skills/
│   └── agents/
└── src/
```

### 3. Multiple addons

```bash
bench init \
  --addon=~/path/to/my-framework-kit \
  --addon=./vendor/internal/my-team-conventions
```

Order matters — later addons win conflicts.

---

## Persistence

Addons passed via `--addon=` are recorded in `.install-record` alongside the install path. `bench rebuild` re-applies the same set automatically, so you don't have to re-specify them every time.

Manage the persisted set:

```bash
bench addon list                       # show registered addons
bench addon add PATH                   # add and rebuild
bench addon remove NAME-OR-PATH        # remove and rebuild
```

---

## Authoring an addon

1. Create a directory with `.bench-addon.yaml`
2. Mirror core's `patterns/` layout for any pattern files you want to add or override
3. Add skills under `skills/<skill-name>/SKILL.md` and agents under `agents/<agent-name>.md`
4. Use `<PLUGIN_ROOT>` in any absolute path references — install-time substitution handles the rest
5. Test against a real project: `bench init --addon=/path/to/your/addon`

### Tips

- **Don't fork files unnecessarily.** If core's pattern is fine as-is, leave it; only contribute files that meaningfully diverge.
- **Match core's pattern frontmatter format** if you want overrides validation to work.
- **One addon, one purpose.** Don't bundle unrelated additions — split into separate addons.
- **Declare `depends_on` honestly.** Specify the minimum core version your addon was authored against.

---

## Roadmap

Future capabilities not in v1:
- Git-URL addon loading (`bench init --addon=git+https://...`)
- Addon registry / discovery
- Per-addon version overrides (e.g., addon contributes a `vue-2` override)
- Cross-addon dependencies
