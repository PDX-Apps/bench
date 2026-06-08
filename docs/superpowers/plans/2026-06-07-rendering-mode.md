# Rendering Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a project declare its rendering model (Vue SPA vs Blade SSR + optional Vue islands) so Bench suppresses the wrong frontend track and asks the question at `/bench-init` — using only the existing addon + concern systems, no new axis.

**Architecture:** Rendering = `--frontend` (component framework) × a page-ownership **addon**. `laravel-blade` gains same-path **replace-overrides** that swap only the page-ownership slice (`vue-page`/`vue-route`/`vue-layout`/`vue-query` + their patterns) to "Blade owns this" redirects, while leaving component patterns intact for islands. A core `rendering` concern writes `.bench/rendering.yaml`; `install.sh` reads it and folds the mapped addon (`blade → laravel-blade`) into the resolved addon set via the existing dependency-expansion path.

**Tech Stack:** Bash (`scripts/install.sh`), Markdown pattern/agent/concern files, the existing layering (same-path replace) + concern + addon-dependency machinery.

**Spec:** `docs/superpowers/specs/2026-06-07-rendering-mode-design.md`

---

## Verification approach (read before starting)

This repo has no unit-test framework for pattern content. The honest test is a **fixture build + grep assertions**: build Bench into a throwaway Laravel-ish project with the addon active, then assert which agent/pattern files landed. Several tasks reuse this helper.

Create it once, in `$CLAUDE_JOB_DIR/tmp` (or `/tmp` if that var is unset):

```bash
# fixture-build.sh — build bench into a temp project and echo the plugin path
set -euo pipefail
BENCH_SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && git -C . rev-parse --show-toplevel 2>/dev/null || pwd)"
BENCH_SRC="/Users/irv/Workspace/pdxapps.com/repos/bench"   # this repo
FIX="${CLAUDE_JOB_DIR:-/tmp}/rmode-fix"
rm -rf "$FIX"; mkdir -p "$FIX"
git -C "$FIX" init -q
printf '{"require":{"laravel/framework":"^13.0","php":"^8.5"}}\n' > "$FIX/composer.json"
printf '{"dependencies":{"vue":"^3.4"}}\n' > "$FIX/package.json"
# optional rendering config passed as $1=blade|spa
if [[ "${1:-}" == "blade" ]]; then mkdir -p "$FIX/.bench"; printf 'mode: blade\n' > "$FIX/.bench/rendering.yaml"; fi
( cd "$FIX" && "$BENCH_SRC/bin/bench" build --frontend=vue "${@:2}" >/dev/null )
echo "$FIX/.claude/plugins/bench"
```

A passing assertion = the agent file's body is the Blade redirect; a failing one = it's still the Vue SPA agent. Each task says exactly what to grep.

---

## Task 1: laravel-blade suppresses the Vue page-ownership slice (replace-overrides)

Swap only `vue-page`/`vue-route`/`vue-layout`/`vue-query` agents + their patterns to Blade redirects. Leave `vue-component`/`vue-composable`/`vue-store` etc. untouched.

**Files:**
- Create: `addons/laravel-blade/agents/vue/vue-page.md`
- Create: `addons/laravel-blade/agents/vue/vue-route.md`
- Create: `addons/laravel-blade/agents/vue/vue-layout.md`
- Create: `addons/laravel-blade/agents/vue/vue-query.md`
- Create: `addons/laravel-blade/patterns/frontend/vue/base/routing/PAGE-001-pages.md`
- Create: `addons/laravel-blade/patterns/frontend/vue/base/routing/ROUTE-001-routes.md`
- Create: `addons/laravel-blade/patterns/frontend/vue/base/routing/LAYOUT-001-layouts.md`
- Create: `addons/laravel-blade/patterns/frontend/vue/base/data/QUERY-001-tanstack-query.md`

- [ ] **Step 1: Confirm the exact base filenames to shadow**

Run: `ls patterns/frontend/vue/base/routing/ patterns/frontend/vue/base/data/ agents/vue/ | grep -E 'page|route|layout|query'`
Expected: `PAGE-001-pages.md`, `ROUTE-001-routes.md`, `LAYOUT-001-layouts.md`, `QUERY-001-tanstack-query.md`, `vue-page.md`, `vue-route.md`, `vue-layout.md`, `vue-query.md`. The addon files above MUST match these names exactly (same-path replace).

- [ ] **Step 2: Write the agent redirect — `vue-page.md`**

`addons/laravel-blade/agents/vue/vue-page.md`:

```markdown
---
name: vue-page
description: In a Blade-rendered project, pages are owned by Blade — not Vue Router.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). Pages, routes,
and layouts are server-owned — there is no client-side Vue page or router track here.

- To build a **page**, use `/blade` (the `blade-page` agent) — a Laravel route + Blade view.
- Vue is still available for **interactive components mounted into Blade pages** — use
  `/vue-component`. Components, composables, and stores work exactly as in an SPA.
- To boot a **full** Vue SPA from a Blade shell route, see the Blade↔SPA handoff pattern
  (`BLADE-005-spa-handoff`).

Do not scaffold a Vue page, `<RouterView>`, or a client route. Redirect the request to `/blade`.
```

- [ ] **Step 3: Write `vue-route.md`**

`addons/laravel-blade/agents/vue/vue-route.md`:

```markdown
---
name: vue-route
description: In a Blade-rendered project, routing is owned by Laravel — not Vue Router.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). URL → view
mapping is a Laravel route returning a Blade view — there is no client Vue Router track.

- To add a route, use `/blade` / your Laravel routes file — not `vue-router`.
- For a full SPA booted from a Blade shell, see `BLADE-005-spa-handoff` (one catch-all route).

Do not scaffold a Vue Router route or `router/index.ts` entry. Redirect to `/blade`.
```

- [ ] **Step 4: Write `vue-layout.md`**

`addons/laravel-blade/agents/vue/vue-layout.md`:

```markdown
---
name: vue-layout
description: In a Blade-rendered project, layouts are Blade layouts — not Vue shells.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). Layouts are
Blade layouts (`@extends` / `<x-layout>`), not Vue app shells.

- To build a layout, use `/blade` (`BLADE-002-layouts`).
- Vue components still mount into Blade layouts as islands — use `/vue-component`.

Do not scaffold a Vue layout component or `<RouterView>` shell. Redirect to `/blade`.
```

- [ ] **Step 5: Write `vue-query.md`**

`addons/laravel-blade/agents/vue/vue-query.md`:

```markdown
---
name: vue-query
description: In a Blade-rendered project, page data comes from the server, not a client query layer.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). Page data is
provided server-side (controller → Blade view props); there is no SPA client-data layer.

- Pass data from a controller into a Blade view — see `/blade` (`BLADE-004-pages`).
- A Vue **island** that needs its own data may fetch directly, or receive initial state as
  props from Blade. There is no project-wide TanStack Query cache to register against.
- A full SPA booted from a Blade shell brings its own data layer — see `BLADE-005-spa-handoff`.

Do not scaffold a TanStack Query hook or query-client registration. Redirect to `/blade`.
```

- [ ] **Step 6: Write the four pattern redirects**

Each pattern file mirrors its base counterpart's path and is a short redirect. Use this body for `addons/laravel-blade/patterns/frontend/vue/base/routing/PAGE-001-pages.md` (adjust the noun for the other three):

```markdown
# PAGE-001 — Pages (Blade-rendered project)

This project renders UI with **Blade**. Pages are **not** Vue Router pages here.

Build pages as Laravel routes returning Blade views — see the Blade pages pattern
(`BLADE-004-pages`) via `/blade`. To boot a full Vue SPA from a Blade shell, see
`BLADE-005-spa-handoff`.

Vue remains available for interactive components mounted into Blade pages (`/vue-component`).
```

`ROUTE-001-routes.md` → "Routes ... routing is Laravel's; see your routes file / `/blade`."
`LAYOUT-001-layouts.md` → "Layouts ... use Blade layouts (`BLADE-002-layouts`)."
`QUERY-001-tanstack-query.md` → "Page data is server-provided; islands fetch directly. No SPA query layer."

No frontmatter `mode:` is needed — a same-path file with no mode is a **full replace** (the default), which is exactly what we want.

- [ ] **Step 7: Verify suppression via a fixture build**

Run (using the helper from the top of this plan):
```bash
PLUGIN=$(bash "$CLAUDE_JOB_DIR/tmp/fixture-build.sh" spa --addon=laravel-blade)
grep -l "owned by Blade\|Blade-rendered project\|Redirect" "$PLUGIN"/agents/vue-page.md
grep -L "Blade" "$PLUGIN"/agents/vue-component.md   # component MUST be untouched (no Blade text)
```
Expected: `vue-page.md` matches (Blade redirect landed); `vue-component.md` is listed by `grep -L` (still the original Vue agent — untouched). If `vue-component.md` contains "Blade", the suppression is too broad — fix.

- [ ] **Step 8: Run the overrides validator (no regressions)**

Run: `bash scripts/validate-overrides.sh`
Expected: exits 0 / all green (these new files are addon replaces, not versioned overrides, so they should not trip base-hash checks).

- [ ] **Step 9: Commit**

```bash
git add addons/laravel-blade/agents/vue addons/laravel-blade/patterns/frontend
git commit -m "laravel-blade: suppress the Vue SPA page-ownership slice (replace-overrides)"
```

---

## Task 2: laravel-blade owns the Blade → full-SPA handoff pattern

**Files:**
- Create: `addons/laravel-blade/patterns/laravel/views/BLADE-005-spa-handoff.md`

- [ ] **Step 1: Confirm the existing BLADE-00x numbering**

Run: `ls addons/laravel-blade/patterns/laravel/views/`
Expected: `BLADE-001-components.md` … `BLADE-004-pages.md`. New file is `BLADE-005-spa-handoff.md`.

- [ ] **Step 2: Write the handoff pattern**

`addons/laravel-blade/patterns/laravel/views/BLADE-005-spa-handoff.md`:

```markdown
# BLADE-005 — Blade → full SPA handoff

When a project is mostly Blade but hands a section (e.g. a dashboard) to a **full** Vue/React
SPA, Blade owns the public/auth pages and **one** route boots the SPA. This is the seam
between the server-rendered track and the client-rendered track — get these four things right.

## 1. The catch-all route

One Laravel route renders the SPA shell for every sub-path so the client router owns
everything below it:

\`\`\`php
// routes/web.php
Route::view('/app/{any?}', 'spa')->where('any', '.*')->middleware('auth');
\`\`\`

## 2. The shell Blade view

A minimal view: a single mount node + the bundler entry. No layout chrome the SPA will redraw.

\`\`\`blade
{{-- resources/views/spa.blade.php --}}
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @vite('resources/js/app.ts')
</head>
<body>
    <div id="app" data-page="{{ json_encode($bootstrap ?? []) }}"></div>
</body>
</html>
\`\`\`

## 3. The bootstrap payload

Pass server state the SPA needs at boot — authenticated user, CSRF, runtime config — via a
data attribute (read once on mount) or a controller that fills `$bootstrap`. Do **not** make
the SPA round-trip for data it could have had at first paint.

\`\`\`js
// resources/js/app.ts
const el = document.getElementById('app')!
const bootstrap = JSON.parse(el.dataset.page || '{}')
// createApp(App, { bootstrap }).use(router).mount(el)
\`\`\`

## 4. The client router base path

The client router's base must match the catch-all mount path so deep links resolve:

\`\`\`js
// createRouter({ history: createWebHistory('/app'), routes })
\`\`\`

## Notes

- Keep auth/marketing pages as ordinary Blade routes — only the SPA section uses the catch-all.
- The SPA's own page/route/layout/data patterns apply **inside** the SPA section; the rest of
  the app is Blade (`/blade`).
- This pattern covers the **full-SPA** handoff only. Mounting individual Vue components as
  islands into otherwise-static Blade pages is left to the project.
```

(The `\`\`\`` fences above are escaped only to keep this plan readable — write real triple-backtick fences in the file.)

- [ ] **Step 3: Verify it builds in**

Run: `PLUGIN=$(bash "$CLAUDE_JOB_DIR/tmp/fixture-build.sh" spa --addon=laravel-blade); ls "$PLUGIN"/patterns-built/laravel/views/BLADE-005-spa-handoff.md`
Expected: the file path prints (it landed in the built plugin).

- [ ] **Step 4: Commit**

```bash
git add addons/laravel-blade/patterns/laravel/views/BLADE-005-spa-handoff.md
git commit -m "laravel-blade: add Blade -> full-SPA handoff pattern (BLADE-005)"
```

---

## Task 3: Add the core `rendering` concern

**Files:**
- Create: `concerns/rendering.md`

- [ ] **Step 1: Re-read a sibling concern for exact frontmatter shape**

Run: `sed -n '1,30p' concerns/layout.md`
Expected: frontmatter with `concern`, `title`, `order`, `detect`, `questions`, `affects`, `output`, then a `## Apply` body. Match this shape.

- [ ] **Step 2: Write the concern**

`concerns/rendering.md`:

```markdown
---
concern: rendering
title: Rendering model
order: 3
detect: ls resources/js/app.* 2>/dev/null >/dev/null && echo spa || (ls resources/views/*.blade.php 2>/dev/null >/dev/null && echo blade || echo spa)
questions:
  - id: mode
    ask: "How does your app render its UI? (spa = Vue/React client app + API; blade = server-rendered Blade, optionally with Vue/React islands)"
    options: [spa, blade]
    default: detect
affects:
  - frontend/vue/base/routing/PAGE-001-pages.md
  - frontend/vue/base/routing/ROUTE-001-routes.md
  - frontend/vue/base/routing/LAYOUT-001-layouts.md
  - frontend/vue/base/data/QUERY-001-tanstack-query.md
output: config:.bench/rendering.yaml
---

## Apply

Write `.bench/rendering.yaml` with the chosen mode:

\`\`\`yaml
mode: blade   # or: spa
\`\`\`

This file is read by `bench build` / `bench rebuild`, which activates the matching
page-ownership addon:

- `mode: blade` → the build folds in **laravel-blade**, which replaces the SPA page-ownership
  slice (the four `affects:` patterns + their `vue-page`/`vue-route`/`vue-layout`/`vue-query`
  agents) with "pages are Blade" redirects, while leaving component/composable/store patterns
  active so Vue islands keep working.
- `mode: spa` → no addon added; the base Vue/React SPA track stays as-is.

Do **not** run `bench addon add` from this concern — writing the config is the whole job; the
build reacts. After writing the file, tell the user to run `bench rebuild` (or that the next
build will pick it up).
```

(Escaped fences again — write real backticks.)

- [ ] **Step 3: Verify the concern is discoverable + well-formed**

Run: `ls concerns/ && grep -E '^(concern|order|output):' concerns/rendering.md`
Expected: `rendering.md` listed; prints `concern: rendering`, `order: 3`, `output: config:.bench/rendering.yaml`.

- [ ] **Step 4: Commit**

```bash
git add concerns/rendering.md
git commit -m "Add core 'rendering' concern (spa|blade -> .bench/rendering.yaml)"
```

---

## Task 4: Build reads `.bench/rendering.yaml` → folds in the mapped addon

**Files:**
- Modify: `scripts/install.sh` (insert between line 229 `_addons_has() {...}` and line 230 `_expand=1`)

- [ ] **Step 1: Read the insertion site**

Run: `sed -n '195,231p' scripts/install.sh`
Expected: the `.bench/` auto-discovery block ends ~line 195; helper funcs `addon_dep_names`/`resolve_addon_dep`/`_addons_has` are defined through line 229; the dependency-expansion `while (( _expand ))` loop starts at line 230. We insert the rendering map **after** the helpers (so `resolve_addon_dep` exists) and **before** the loop (so the mapped addon's own deps still expand).

- [ ] **Step 2: Insert the rendering→addon mapping**

After the line `_addons_has() { ... return 1; }` (currently line 229) and before `_expand=1`, insert:

```bash
# ---------- Rendering mode -> page-ownership addon ----------
# A project declares its rendering model in .bench/rendering.yaml (written by the
# `rendering` concern). We map the mode to the addon that owns page rendering and fold it
# into ADDONS here — BEFORE dependency expansion, so the mapped addon's own deps resolve.
# Consistent with concerns-produce-config / build-reacts: the concern never runs `addon add`.
RENDERING_YAML="$PROJECT_ROOT/.bench/rendering.yaml"
if [[ -f "$RENDERING_YAML" ]]; then
  rmode=$(grep -E '^mode:' "$RENDERING_YAML" | head -1 | sed -E 's/^mode:[[:space:]]*//; s/[[:space:]#].*$//')
  case "$rmode" in
    blade) rmode_addon="laravel-blade" ;;
    spa|"") rmode_addon="" ;;
    *) echo "WARNING: .bench/rendering.yaml mode '$rmode' unknown; expected spa|blade" >&2; rmode_addon="" ;;
  esac
  if [[ -n "$rmode_addon" ]]; then
    rmode_path="$(resolve_addon_dep "$rmode_addon")"
    if [[ -z "$rmode_path" ]]; then
      echo "WARNING: rendering mode '$rmode' needs addon '$rmode_addon' — not found in $PLUGIN_SRC/addons" >&2
    elif ! _addons_has "$rmode_path"; then
      ADDONS+=("$rmode_path")
      echo "  + rendering mode '$rmode' -> addon $rmode_addon"
    fi
  fi
fi
```

- [ ] **Step 3: Lint the script**

Run: `bash -n scripts/install.sh`
Expected: no output (syntax OK).

- [ ] **Step 4: Verify the mapping activates laravel-blade WITHOUT an explicit --addon flag**

Run (note: `blade` arg makes the helper write `.bench/rendering.yaml`, and NO `--addon` is passed):
```bash
PLUGIN=$(bash "$CLAUDE_JOB_DIR/tmp/fixture-build.sh" blade)
grep -q "owned by Blade\|Blade-rendered project\|Redirect" "$PLUGIN"/agents/vue-page.md && echo "SUPPRESSION-ACTIVE"
ls "$PLUGIN"/patterns-built/laravel/views/BLADE-005-spa-handoff.md
grep -L "Blade" "$PLUGIN"/agents/vue-component.md   # still untouched
```
Expected: prints `SUPPRESSION-ACTIVE`; the BLADE-005 path lists; `vue-component.md` listed by `grep -L`. This proves config alone (no `--addon`) pulled in laravel-blade and applied suppression.

- [ ] **Step 5: Verify SPA mode adds nothing**

Run:
```bash
PLUGIN=$(bash "$CLAUDE_JOB_DIR/tmp/fixture-build.sh" spa)   # no rendering.yaml written
grep -L "owned by Blade" "$PLUGIN"/agents/vue-page.md       # should be the ORIGINAL vue page agent
test ! -e "$PLUGIN"/patterns-built/laravel/views/BLADE-005-spa-handoff.md && echo "NO-BLADE-IN-SPA"
```
Expected: `vue-page.md` listed by `grep -L` (no Blade redirect); prints `NO-BLADE-IN-SPA`.

- [ ] **Step 6: Commit**

```bash
git add scripts/install.sh
git commit -m "install: map .bench/rendering.yaml mode -> page-ownership addon"
```

---

## Task 5: React mirror of the suppression slice

Same as Task 1 for React, so `--frontend=react` Blade projects are covered. Confirm the React agent/pattern names first — they may differ from Vue.

**Files:**
- Create: `addons/laravel-blade/agents/react/react-page.md`
- Create: `addons/laravel-blade/agents/react/react-route.md`
- Create: `addons/laravel-blade/agents/react/react-layout.md`
- Create: `addons/laravel-blade/agents/react/react-query.md`
- Create: matching pattern redirects under `addons/laravel-blade/patterns/frontend/react/base/...`

- [ ] **Step 1: Discover the exact React names + paths**

Run: `ls agents/react/ | grep -E 'page|route|layout|query'; echo '---'; ls patterns/frontend/react/base/routing/ patterns/frontend/react/base/data/ 2>/dev/null`
Expected: a list like `react-page.md`, `react-route.md`, `react-layout.md`, `react-query.md` and the React routing/data pattern filenames. **Use whatever names actually print** — if React's data pattern is not `QUERY-001` or its router files differ, mirror the real names, not the Vue ones.

- [ ] **Step 2: Write the four React agent redirects**

Mirror Task 1 Step 2–5 wording, swapping "Vue"→"React", "`<RouterView>`"→"the React Router outlet / `<Outlet>`", "`/vue-component`"→"`/react-component`", "composables"→"hooks", "TanStack Query hook"→"TanStack Query / React Query hook". Example `addons/laravel-blade/agents/react/react-page.md`:

```markdown
---
name: react-page
description: In a Blade-rendered project, pages are owned by Blade — not the React router.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). Pages, routes,
and layouts are server-owned — there is no client-side React page or router track here.

- To build a **page**, use `/blade` (the `blade-page` agent) — a Laravel route + Blade view.
- React is still available for **interactive components mounted into Blade pages** — use
  `/react-component`. Components and hooks work exactly as in an SPA.
- To boot a **full** React SPA from a Blade shell route, see `BLADE-005-spa-handoff`.

Do not scaffold a React page, `<Outlet>`, or a client route. Redirect the request to `/blade`.
```

Write `react-route.md`, `react-layout.md`, `react-query.md` analogously (mirroring Task 1 Steps 3–5).

- [ ] **Step 3: Write the React pattern redirects**

Mirror Task 1 Step 6 at the real React paths discovered in Step 1. Same short "this is a Blade project; use `/blade`" redirect body, React nouns.

- [ ] **Step 4: Verify with a React fixture build**

Temporarily point the fixture at React: 
```bash
FIX="${CLAUDE_JOB_DIR:-/tmp}/rmode-fix-react"; rm -rf "$FIX"; mkdir -p "$FIX"; git -C "$FIX" init -q
printf '{"require":{"laravel/framework":"^13.0","php":"^8.5"}}\n' > "$FIX/composer.json"
printf '{"dependencies":{"react":"^19.0","react-dom":"^19.0"}}\n' > "$FIX/package.json"
mkdir -p "$FIX/.bench"; printf 'mode: blade\n' > "$FIX/.bench/rendering.yaml"
( cd "$FIX" && /Users/irv/Workspace/pdxapps.com/repos/bench/bin/bench build --frontend=react >/dev/null )
PLUGIN="$FIX/.claude/plugins/bench"
grep -q "owned by Blade" "$PLUGIN"/agents/react-page.md && echo "REACT-SUPPRESSION-ACTIVE"
grep -L "Blade" "$PLUGIN"/agents/react-component.md
```
Expected: prints `REACT-SUPPRESSION-ACTIVE`; `react-component.md` listed by `grep -L` (untouched).

- [ ] **Step 5: Commit**

```bash
git add addons/laravel-blade/agents/react addons/laravel-blade/patterns/frontend/react
git commit -m "laravel-blade: mirror page-ownership suppression for React"
```

---

## Task 6: Documentation + working-notes

**Files:**
- Modify: `docs/architecture.md` (rendering section)
- Modify: `docs/addons.md` (laravel-blade row)
- Modify: `addons/laravel-blade/README.md`
- Modify: `docs/working-notes.md` (mark idea-bank item resolved)

- [ ] **Step 1: architecture.md — add rendering as framework × page-ownership**

Find the frontend/axis discussion (Run: `grep -n "frontend\|vue|react|none\|axis" docs/architecture.md | head`) and add a short subsection stating: the `--frontend` axis is the **component framework**; **rendering model** (SPA vs Blade SSR) is a separate concern that activates a page-ownership addon (`laravel-blade`) which replace-overrides the page/route/layout/data slice while keeping component patterns. Note Inertia/Livewire as future modes of the same shape.

- [ ] **Step 2: addons.md — update the laravel-blade row**

Find it (Run: `grep -n "laravel-blade" docs/addons.md`) and change the description to reflect that it now **suppresses** the SPA page-ownership slice and owns the Blade→SPA handoff — not just an additive `/blade` track. Add a one-liner under the Laravel UI table that the `rendering` concern selects it automatically.

- [ ] **Step 3: laravel-blade README — document modes + handoff**

Run: `cat addons/laravel-blade/README.md` then add a "Rendering modes" section: pure Blade (`--frontend=none`), Blade + framework islands (`--frontend=vue|react` + this addon, component patterns stay, page slice suppressed), and the BLADE-005 full-SPA handoff. Mention activation via the `rendering` concern / `.bench/rendering.yaml`.

- [ ] **Step 4: working-notes.md — mark resolved**

Find the "Frontend rendering MODE" idea-bank bullet (Run: `grep -n "rendering MODE\|Blade UI apps\|Blade core-vs-addon" docs/working-notes.md`) and prefix it with `✅ DONE (2026-06-07): ` plus a one-line pointer to the spec `docs/superpowers/specs/2026-06-07-rendering-mode-design.md`. Leave the Inertia/Livewire extension note as still-pending.

- [ ] **Step 5: Verify the docs reference reality**

Run: `grep -n "rendering" docs/architecture.md docs/addons.md addons/laravel-blade/README.md`
Expected: each file now mentions rendering mode; no leftover claim that laravel-blade is "additive only".

- [ ] **Step 6: Commit**

```bash
git add docs/architecture.md docs/addons.md addons/laravel-blade/README.md docs/working-notes.md
git commit -m "docs: rendering mode (framework x page-ownership); laravel-blade suppression + handoff"
```

---

## Final verification

- [ ] **Build matrix smoke test** — run all four cells and eyeball:

```bash
H="$CLAUDE_JOB_DIR/tmp/fixture-build.sh"
echo "SPA:";         P=$(bash "$H" spa);                 grep -Lq Blade "$P"/agents/vue-page.md && echo "  vue page active (correct)"
echo "Blade+islands:"; P=$(bash "$H" blade);             grep -q Blade "$P"/agents/vue-page.md && grep -Lq Blade "$P"/agents/vue-component.md && echo "  page suppressed + component kept (correct)"
```
Expected: SPA cell keeps the Vue page agent; Blade cell suppresses the page agent but keeps the component agent.

- [ ] **Overrides validator green:** `bash scripts/validate-overrides.sh` → exits 0.

- [ ] **Clean up fixtures:** `rm -rf "${CLAUDE_JOB_DIR:-/tmp}"/rmode-fix*`

---

## Self-review notes (author)

- **Spec coverage:** Work items 1–4 from the spec → Tasks 1,2,3,4; React mirror (spec "affected files" + open question) → Task 5; docs → Task 6. Extension point (Inertia/Livewire) intentionally not built — noted in Task 6 Step 4.
- **Type/name consistency:** agent names (`vue-page`/`vue-route`/`vue-layout`/`vue-query`), config key (`mode:`), file (`.bench/rendering.yaml`), addon name (`laravel-blade`), pattern id (`BLADE-005-spa-handoff`) are used identically across Tasks 1, 3, 4, 6.
- **Known soft spot:** the fixture build assumes `bin/bench build` runs from a fresh git-init'd dir with only composer.json/package.json. If `build` requires more (e.g. a real `.git` remote or vendor/), Task 1 Step 7 will surface it immediately — adjust the fixture, not the design.
```