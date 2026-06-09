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

## Pass 1 — Concerns (the essentials; reliable, always asked)

Run the declared concerns at `<PLUGIN_ROOT>/concerns/*.md` (core + installed addons), sorted by `order`. For each:

1. Read it; if `when:` is a shell test, run it and skip on failure.
2. Run `detect:` (if present) for a suggested default — both the concern-level `detect:` and any **per-question `detect:`** (a question can carry its own, e.g. reading a value out of `components.json`). Use the detected value to pre-fill that question.
3. **Ask its `questions`** with `AskUserQuestion` (bundle a concern's questions; pre-fill the detect/default). The user accepts or changes; skipping a concern is allowed.
4. Delegate to `concern-runner` (Task) with `{ concern_file, answers, project_root: cwd, defer_rebuild: true }`.

This is the part that must NOT be left to guessing — auth/permissions/test-framework etc. always get asked, and each concern updates **all** the patterns in its `affects:` list (not whichever a scan happened to notice). See `<PLUGIN_ROOT>/patterns-built/authoring/CONCERNS.md`.

## Pass 2 — Discovery (optional; the long tail)

Then ask the user how far to go:

> "Concerns set up. Want me to also (a) **scan** the codebase for any other non-standard conventions, (b) look for **specific things you name**, or (c) **stop here**?"

- **(a) scan** → delegate to `project-scanner` (read-only) for deviations + slice candidates; present an opt-in checklist.
- **(b) user-directed** → take the things the user names ("we wrap responses in X", "we have an app/Reports domain") and route them directly.
- **(c) stop** → done.

For each accepted item: override → the matching author (`pattern-author`/`skill-author`/`agent-author`, `intent: fork`, `defer_rebuild: true`); slice candidate → the slice sequence (`pattern-author` capture → `skill-author` new). Show drafts for approval.

## Pass 3 — Matching addons (offer, don't fork)

Some conventions are better served by a **bundled addon** than a project override — a package has a whole pattern set, not a one-line tweak. List what's available and map detections to addons:

```bash
<PLUGIN_ROOT>/bin/bench addon available     # name + description of every bundled addon
```

Scan `composer.json` / `package.json` for packages that have a matching addon (e.g. `spatie/laravel-permission` → `spatie-permission`, `laravel/octane` → `laravel-octane`, `nwidart/laravel-modules` → `laravel-modules`, `spatie/laravel-query-builder` → `spatie-query-builder`, Inertia/Livewire/Filament/Cashier/Scout/Horizon/Socialite → their addons). For each match, **offer** to install it:

> "Detected `spatie/laravel-permission` — there's a `spatie-permission` addon (roles/permissions scaffolding + authz patterns). Add it?"

On yes, run `<PLUGIN_ROOT>/bin/bench addon add <name>` (it rebuilds). Prefer an addon over a hand-written override when one exists — don't fork patterns a packaged addon already owns.

## Finish — one rebuild + summary

Run the installed CLI (`<PLUGIN_ROOT>` is substituted to this project's real install path at build time — never guess a path or use another project's copy). The install already exists from `bench build`; this only re-resolves the new `.bench/` overrides:

```bash
<PLUGIN_ROOT>/bin/bench rebuild
```
```
Bench tailored to {project}.
Concerns configured: {list}
Overrides/slices:    {list}
Skipped:             {list}

Your CLAUDE.md was untouched. Adjust anytime:
  /bench-configure <concern>   ·   /bench-override <change>   ·   /bench-slice <domain>
```

## Notes
- **Never writes CLAUDE.md** — project context rides inside the `.bench/` overrides each concern/author writes.
- **Everything is opt-in.** A run that captures nothing is valid.
- **One rebuild** at the end (`defer_rebuild: true` everywhere).
- **The CLI is `<PLUGIN_ROOT>/bin/bench`** — the installed copy for *this* project. It self-delegates `rebuild`/`addon` to the real bench source via the install's `.install-source` record, so you don't need to know where bench is cloned. Never substitute a guessed path or another project's plugin copy. If `rebuild` reports no install, `bench build` hasn't run for this project yet — that's the prerequisite, surface it rather than improvising.
