# Bench

> Teach AI coding assistants the conventions of *your* Laravel + Vue/React project — once — so the code they generate lands in the right place, in the right shape, the first time.

**Status: beta (v0.8.x).** Works end-to-end; not yet battle-tested across many projects. API soft-stable until v1.0.0 — see [CHANGELOG.md](./CHANGELOG.md).

Built for [Claude Code](https://docs.claude.com/en/docs/claude-code) today; designed to extend to other AI CLIs.

---

## The problem

AI coding assistants generate *generic*-best-practices code. But real projects have a specific framework version, a test runner, an auth strategy, a response shape, a folder layout, a UI library. Generic code fights all of that — so you spend the review fixing placement and idioms.

Bench is a pluggable kit of **slash commands + worker agents + versioned framework knowledge** that adapts to *your* project. You describe a feature; Bench routes it to a worker that reads only the relevant conventions and produces code that fits.

---

**Contents:** [Install](#install) · [Using Bench](#using-bench) · [How it works](#how-it-works) · [Addons](#addons) · [CLI reference](#cli-reference) · [Docs](#docs) · [License](#license)

---

## Install

Clone Bench once; then build it into each project you want to use it in.

```bash
# Once, globally — clone Bench somewhere stable:
git clone git@github.com:PDX-Apps/bench.git ~/tools/bench

# Then, once per project — from the project root:
cd ~/my-app
~/tools/bench/bin/bench build
```

(Tip: symlink `~/tools/bench/bin/bench` onto your `PATH` so it's just `bench build` everywhere — see `scripts/install-cli.sh`.)

`bench build` detects your Laravel / PHP / Vue / React versions, **builds a copy of the plugin for this project** into `.claude/plugins/bench/` (patterns resolved for your versions, your `.bench/` overrides + addons merged), and registers it in `.claude/settings.json`.

> **Bench is per-project, not a global plugin.** Each project gets its own built copy — there is no single build that's correct for every version + override set. Your project must be its own git root.

Now open Claude Code in the project and head to **[Using Bench](#using-bench)** → start with `/bench-init`.

---

## Using Bench

You work inside Claude Code with slash commands. Onboard the project first, then generate code, and tailor Bench as you discover the project's quirks.

### 1. Onboard — `/bench-init`

The first thing to run in a new project. It walks the **concerns** — a guided interview over the essentials (auth strategy, test framework, permissions model, response shape, layout), where each concern knows exactly which patterns it owns and updates *all* of them — then offers to scan for anything else non-standard. Everything it captures lands in a committed **`.bench/`** folder that travels with your repo. Re-run a single concern anytime with `/bench-configure <name>`.

Bench **never writes your `CLAUDE.md`** — your project context lives in `.bench/`.

### 2. Generate code

Describe what you want; Bench routes it to the right worker(s):

- **One artifact** — `/laravel create an endpoint to list a user's orders` · `/vue-component OrderCard`
- **A whole feature** — `/bench implement <feature, PRD, or ticket>` spawns the agents in dependency order (migration → model → controller → … → tests).
- **Frontend** — `/frontend <request>` routes to your Vue *or* React stack (fixed at build, no guessing).
- `/help` lists everything available in this project.

### 3. Tailor to your conventions

When generated code doesn't match how *your* team does it, teach Bench — no core edits. Both commands write to your committed `.bench/` folder; run `bench rebuild` afterward to re-resolve.

- **`/bench-override`** — change how an *existing* artifact is generated. Describe it in plain language — "we don't use `toDto`, we return a `Mapper`", "controllers extend `ApiController`", "tests are Pest, co-located" — and Bench writes a targeted override of the affected pattern(s), layered onto core so a Bench upgrade won't clobber it.
- **`/bench-slice`** — teach Bench a *new* artifact type unique to your project. Point it at one of your own domains (`/bench-slice app/Reports`) and it scaffolds a full Bench-grade slice — a `/report` skill, a worker agent, and the pattern(s) describing how your reports are built — so every future report generates the same way.

How overrides and addons actually layer onto core — append, replace, and the rest — is covered in [Layering](./docs/layering.md).

---

## How it works

Three layers. The main conversation stays at the **feature level** — you say what you want; the implementation details and pattern files stay out of your context window.

| Layer | What it is | Example |
|-------|-----------|---------|
| **Skills** | Slash commands — thin routers. Parse your request, inspect the project, resolve ambiguity, then delegate. | `/bench`, `/laravel`, `/frontend`, `/vue-component` |
| **Agents** | Subagents that do the work in isolated context — read only the patterns a task needs, scaffold the artifact, return a summary. | `controller`, `vue-component`, `migration` |
| **Patterns** | Version-aware markdown describing *how* to write each artifact. The shared knowledge base. | `CONTROLLER-001`, `STORE-001`, `MIGRATION-001` |

```
you → /laravel "add an Orders API"
        └─ skill routes → controller · request · resource · route agents
              └─ each reads its pattern(s) → writes code that matches your project
```

**Patterns are the only version-aware layer.** `base/` targets the latest idioms — currently **Laravel 13 + PHP 8.5** (and Vue 3 / current React) — while `overrides/laravel-12/`, `overrides/php-8.4/` carry rollbacks for older versions. Skills and agents are single-copy and name no version-specific syntax — so the same agent emits L13 *or* L12 code depending on what your project resolved at build.

Out of the box: **4 routers** (`/bench`, `/laravel`, `/frontend`, `/help`) + **27 Laravel** and **10 Vue / 10 React** component skills, backed by version-aware patterns for both stacks.

---

## Addons

Addons are opt-in plugins that extend — or *replace* — what core ships: adding commands, agents, and patterns, or swapping a default (the data layer, the router, the styling system) for an alternative. They layer on the same way as your own overrides (see [Layering](./docs/layering.md)), and can declare `depends_on.addons` so installing one pulls in what it needs (e.g. `bench-quality` pulls `bench-ci` + `bench-playwright` and delegates to their agents instead of duplicating them).

```bash
bench addon add tailwind     # by bundled name
bench addon add /path/to/my-addon  # or a path
```

One addon — **`bench-manager`** — is bundled and loaded by default; it provides the `/bench-*` commands above. Everything else is opt-in. Bench ships **40 addons** across:

[Setup & workflow](./docs/addons.md#setup--workflow) · [Laravel packages](./docs/addons.md#laravel-packages) · [Laravel UI](./docs/addons.md#laravel-ui) · [Frontend styling](./docs/addons.md#frontend-styling) · [Component libraries](./docs/addons.md#frontend-component-libraries) · [Data & routing](./docs/addons.md#frontend-data--routing) · [Meta-frameworks](./docs/addons.md#meta-frameworks) · [Testing](./docs/addons.md#testing) · [Docs](./docs/addons.md#documentation)

Full catalog + how to author your own: [docs/addons.md](./docs/addons.md).

---

## CLI reference

```bash
bench build    [--copy|--symlink] [--addon=NAME ...]   # build + register Bench for this project
bench rebuild  [--addon=NAME ...]                      # re-resolve after editing .bench/ or upgrading a dependency
bench addon    list | add <name|path> | remove <name>  # manage addons
bench profile  [show | set <compact|standard>]         # compact = router/help skills only (agents always ship)
bench status                                           # detected versions, addons, profile, install path
```

**Version flags** — `build` and `rebuild` auto-detect versions from `composer.json` / `package.json`; pass any of `--laravel=13 --php=8.5 --frontend=vue|react|none --vue=3` to override that detection. Run **`bench help`** for the complete, always-current flag reference.

---

## Docs

- [docs/architecture.md](./docs/architecture.md) — the layers + build pipeline in depth
- [docs/addons.md](./docs/addons.md) — addon catalog + how to author one
- [docs/layering.md](./docs/layering.md) — override/addon modes in full
- [CHANGELOG.md](./CHANGELOG.md)

---

## License

MIT — see [LICENSE](./LICENSE).
