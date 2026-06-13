---
description: |
  First-run setup that tailors Bench to THIS project. Walks the essential concerns
  (auth, test framework, permissions, response shape, layout, + any addon concerns)
  via a guided interview, then offers to scan for any other deviations and to build
  slices for your domains. Use on "/bench-init", "set up Bench for this project",
  "tailor Bench to my codebase", "initialize Bench". Does NOT write your CLAUDE.md.
argument-hint: "[--depth=shallow|standard|deep]"
---

You're the **/bench-init** skill. Tailor Bench to this project in two passes — declared **concerns** first (reliable: every essential gets asked + every affected pattern updated), then optional **discovery** for the long tail. You own the interview; authoring is delegated. You **never write the project's CLAUDE.md**.

The user's request: **$ARGUMENTS**

## Pass 0 — Understand the layout (read the README, don't guess)

Before anything, ground yourself in how **this** repo is organized. The project's own **`README.md`** (and `docs/`) almost always documents the layout far better than any directory scan can infer — read them first. Pull out: where the Laravel app(s) live, which directories are frontend **apps** vs **shared packages**, what each app actually is (SPA / Electron / Capacitor / API), and where shared components/composables/types belong. This is your source of truth for routing generated code to the right place — prefer it over guessing from folder names or `package.json` heuristics. If the README doesn't cover it, fall back to inspecting `composer.json`/`package.json` across the workspace, and **ask the user** rather than assuming.

**Frontend safety net.** Run `<PLUGIN_ROOT>/bin/bench status` and read the active frontend. If it says **none** but the layout shows a Vue/React app, the initial `bench build` missed the framework — **offer to fix it**, because the frontend is fixed at build time (a plain `rebuild` just replays `none`):

> "Your build is backend-only, but the README shows `apps/web` is a Vue SPA — its skills/agents weren't generated. Re-run the build with Vue?"

On yes: `<PLUGIN_ROOT>/bin/bench build --frontend=vue --vue=<detected>` (or `react`). This is the one place bench-init runs `build` with flags rather than a plain `rebuild`. Then continue.

## Pass 1 — Concerns (the essentials; reliable, always asked)

Run the declared concerns at `<PLUGIN_ROOT>/concerns/*.md` (core + installed addons), sorted by `order`. For each:

1. Read it; if `when:` is a shell test, run it and skip on failure.
2. Run `detect:` (if present) for a suggested default — both the concern-level `detect:` and any **per-question `detect:`** (a question can carry its own, e.g. reading a value out of `components.json`). Use the detected value to pre-fill that question.
3. **Ask its `questions`** with `AskUserQuestion` (bundle a concern's questions; pre-fill the detect/default). A question with `multi: true` is a checklist — render it as a `multiSelect` and record its answer as the **list** of chosen options (empty list if none). The user accepts or changes; skipping a concern is allowed.
4. Delegate to `concern-runner` (Task) with `{ concern_file, answers, project_root: cwd, defer_rebuild: true }`.

This is the part that must NOT be left to guessing — auth/permissions/test-framework etc. always get asked, and each concern updates **all** the patterns in its `affects:` list (not whichever a scan happened to notice). See `<PLUGIN_ROOT>/patterns-built/authoring/CONCERNS.md`.

## Pass 2 — Discovery (optional; the long tail)

Then ask the user how far to go:

> "Concerns set up. Want me to also (a) **scan** the codebase for any other non-standard conventions, (b) look for **specific things you name**, or (c) **stop here**?"

- **(a) scan** → delegate to `project-scanner` (read-only) for deviations + slice candidates; present an opt-in checklist.
- **(b) user-directed** → take the things the user names ("we wrap responses in X", "we have an app/Reports domain") and route them directly.
- **(c) stop** → done.

For each accepted item: override → the matching author (`pattern-author`/`skill-author`/`agent-author`, `intent: fork`, `defer_rebuild: true`); slice candidate → the slice sequence (`pattern-author` capture → `skill-author` new). Show drafts for approval.

## Pass 3 — Matching addons (offer as a checklist)

Many conventions are better served by a **bundled addon** than a hand-written override — a package has a whole pattern set, not a one-line tweak. Detect what's installed and offer the matches as one multi-select.

**Scan monorepo-aware.** Real deps are often NOT at the repo root (a turbo/nx/pnpm root is just orchestration). Read every manifest, skipping `vendor/`/`node_modules/`:

- `composer.json` — root **and** `apps/*/`, `packages/*/`, `services/*/`
- `package.json` — root **and** `apps/*/`, `packages/*/`

List the bundled addons, then map detections across **both** ecosystems:

```bash
<PLUGIN_ROOT>/bin/bench addon available     # name + description of every bundled addon
```

- **Laravel** — `spatie/laravel-permission`→`spatie-permission`, `spatie/laravel-query-builder`→`spatie-query-builder`, `laravel/octane`→`laravel-octane`, `laravel/horizon`→`laravel-horizon`, `laravel/telescope`→`laravel-telescope`, `laravel/scout`→`laravel-scout`, `laravel/cashier`→`laravel-cashier`, `laravel/socialite`→`laravel-socialite`, `laravel/reverb`→`laravel-reverb`, `laravel/pennant`→`laravel-pennant`, `laravel/boost`→`laravel-boost`, `nwidart/laravel-modules`→`laravel-modules`, `inertiajs/inertia-laravel`→`inertia`, `livewire/livewire`→`livewire`, `filament/filament`→`filament`, `dedoc/scramble` or `darkaonline/l5-swagger`→`laravel-swagger`, `pdxapps/preflight`→`preflight`.
- **Frontend** — `vuetify`→`vuetify`, `primevue`→`primevue`, `quasar`→`quasar`, `@chakra-ui/react`→`chakra`, `@mui/material`→`mui`, `radix-ui`/`@radix-ui/*`→`radix`, a `components.json`→`shadcn`/`shadcn-vue`, `tailwindcss`→`tailwind`, `unocss`→`unocss`, `@pinia/colada`→`pinia-colada`, `@tanstack/react-router`→`tanstack-router`, `next`→`nextjs`, `nuxt`→`nuxt`, framework-mode `react-router`→`remix`, `@playwright/test`→`playwright`.

Present every match in **one `AskUserQuestion` (multiSelect)** — "Detected these packages with matching addons — which should I install?" — describing what each addon adds. On confirm, install the chosen set: `<PLUGIN_ROOT>/bin/bench addon add <name>` per addon (batch them, then one rebuild at the end). Prefer an addon over a hand-written override when one exists — don't fork patterns a packaged addon already owns.

## Finish — one rebuild + summary

Run the installed CLI (`<PLUGIN_ROOT>` is substituted to this project's real install path at build time — never guess a path or use another project's copy). The install already exists from `bench build`; this only re-resolves the new `.bench/` overrides:

```bash
<PLUGIN_ROOT>/bin/bench rebuild
```

**Then tell the user to run `/reload-plugins`.** Claude Code loaded the plugin at session start, so any addons installed or skills/agents changed during this run are NOT live in this session until plugins are reloaded. End the summary with this as the explicit next action — without it, the new `/<addon>` commands won't appear.

```
Bench tailored to {project}.
Concerns configured: {list}
Addons installed:    {list}
Overrides/slices:    {list}
Skipped:             {list}

▶ Run /reload-plugins now to load the new addons + commands into this session.

Your CLAUDE.md was untouched. Adjust anytime:
  /bench-configure <concern>   ·   /bench-override <change>   ·   /bench-slice <domain>
```

## Notes
- **End with `/reload-plugins`** whenever this run installed an addon or created a new skill/agent (a slice) — Claude Code registers skills/agents at plugin load, so they're invisible until reloaded. (Pure pattern/override changes are read live and don't need a reload, but if in doubt, reloading is harmless — so always surface it after a bench-init run that touched addons.)
- **Never writes CLAUDE.md** — project context rides inside the `.bench/` overrides each concern/author writes.
- **Everything is opt-in.** A run that captures nothing is valid.
- **One rebuild** at the end (`defer_rebuild: true` everywhere).
- **The CLI is `<PLUGIN_ROOT>/bin/bench`** — the installed copy for *this* project. It self-delegates `rebuild`/`addon` to the real bench source via the install's `.install-source` record, so you don't need to know where bench is cloned. Never substitute a guessed path or another project's plugin copy. If `rebuild` reports no install, `bench build` hasn't run for this project yet — that's the prerequisite, surface it rather than improvising.
