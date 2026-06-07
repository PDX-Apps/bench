# METHODOLOGY — Layered project scan

Shared methodology used by the `bench-manager` authoring agents (the project scanner, `pattern-author`, `skill-author`, `agent-author`). Codifies how to understand a codebase efficiently — sample-driven, token-conscious, layered from cheap-and-broad to expensive-and-targeted.

The goal is to triangulate the project's actual conventions with **minimum file reads** and **maximum signal**, then ask questions only where the code is ambiguous.

---

## The six layers

Always work top-to-bottom. Stop at the first layer that resolves your current question; only descend deeper when needed.

### Layer 1 — Manifests (cheap, high signal)

Always read these first. They reveal the entire tech stack in ~10 file reads:

| File | What it tells you |
|------|-------------------|
| `composer.json` | Laravel + PHP versions, packages (spatie, larastan, pest vs phpunit, fortify, sanctum, horizon, reverb, telescope, cashier, …) |
| `package.json` | Vue/React major, UI library deps (quasar, vuetify, mui, radix, headlessui, …), state lib (pinia/zustand/redux-toolkit), data-fetching (tanstack-query, swr), forms (react-hook-form, vee-validate), i18n, build tool (vite/webpack) |
| `pnpm-workspace.yaml` / `lerna.json` / root `package.json:workspaces` | Monorepo layout — which subdirs are apps vs packages |
| `turbo.json` / `nx.json` / `lerna.json` | Build orchestrator + task graph |
| `tsconfig.json` (root + per-app) | TS strictness, path aliases (`@/`, `@app/`, `@tributary/`) |
| `eslint.config.{js,ts}` / `.eslintrc*` | Lint rules + style conventions |
| `phpunit.xml` / `phpstan.neon` / `pint.json` | Backend test/static-analysis/format conventions |
| `vite.config.{ts,js}` / `electron-vite.config.ts` | Bundle entry points, plugins |
| `.editorconfig` / `.prettierrc` | Whitespace/quote/semicolon style |
| `.nvmrc` / `.python-version` | Runtime version pinning |
| `.gitignore` | What the team considers generated vs source |

**Output of this layer**: A "stack profile" — list of (lib, version, role).

### Layer 2 — Project shape (cheap, structural)

Run a single `find` to map the directory layout. Don't read files yet.

```bash
find . -maxdepth 4 -type d \
  -not -path './node_modules*' \
  -not -path './vendor*' \
  -not -path './.git*' \
  -not -path './dist*' \
  -not -path './build*' \
  -not -path './.next*' \
  -not -path './storage*' \
  | sort
```

Look for:
- **Apps vs packages structure** — `apps/{name}/` + `packages/{name}/` = monorepo
- **Per-module feature folders** — `Modules/{Name}/` (Laravel modules) or `src/modules/{Name}/` (Vue/React modules)
- **Flat-by-type** — `src/components/`, `src/composables/`, `src/stores/` (no module subdirs)
- **Domain-driven** — `src/Domain/`, `src/Infrastructure/`, `src/Application/`
- **Where layouts/routes/i18n live** — Tells you the framework's coupling style
- **`tests/`, `__tests__/`, co-located `*.spec.*`** — Test location convention
- **`docs/`** — Project owns documentation
- **`.claude/`, `CLAUDE.md`** — Project is already AI-aware

**Output**: A directory map + classification (monorepo / single-app, per-module / flat-by-type).

### Layer 3 — Representative sampling (selective reads)

This is where you actually read code. **Don't read everything.** Pick representative files per domain and triangulate.

**Strategy:**

1. For each artifact type you care about (controller, model, component, etc.), find existing examples:
   ```bash
   find . -path '*/Http/Controllers/*.php' -not -path '*/vendor/*' | head -5
   find . -path '*/components/*.vue' -not -path '*/node_modules/*' | head -5
   ```

2. Read the **first 2-3 representative samples** — usually enough to learn naming, structure, common patterns.

3. **Validate with grep** instead of more reads. Example: "do all controllers use `extends Controller`?" → `grep -l "extends Controller" $(find . -name '*Controller.php')`. Cheap, broad.

4. **Note divergences.** If 9/10 services are constructor-injected but 1 reaches for a global helper, the convention is the former; the outlier might be legacy or a new direction (worth asking — and check git recency, Layer 5).

**Output**: A list of `(artifact_type, observed_convention, confidence)` tuples. Confidence = "high" (consistent across all samples), "medium" (mostly consistent, some variation), "low" (no clear convention).

### Layer 4 — Prose docs (high signal when present)

Always read if they exist:

- `README.md` — usually has stack overview + "how to run" + sometimes architecture notes
- `CLAUDE.md` — explicit AI-conventions doc (might already exist; refining vs creating from scratch are different operations)
- `docs/` — design docs, ADRs, internal RFCs
- `ARCHITECTURE.md` / `CONTRIBUTING.md` — team's own conventions
- `.github/pull_request_template.md` — what the team values in PRs (often reveals testing/review conventions)

Prose tells you the **why** that code can never reveal. Skipping prose is a top mistake.

**Output**: Quotes / paraphrases of any stated conventions, plus reading-between-the-lines on what the team values.

### Layer 5 — Git activity (cheap, recency signal)

```bash
git log --since="3 months ago" --name-only --pretty=format: \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -30
```

Files touched a lot recently = active areas where current convention lives. Files untouched = either rock-solid or legacy.

If your scan finds two conventions for the same thing, **the one in more-recently-touched files is the current convention**. The other is probably being phased out.

**Output**: A heatmap of active vs cold areas. Use to weight conflicting signals.

### Layer 6 — Interview (expensive, last resort)

ONLY ask the user about things the code can't reveal:

- **Domain language** — "I see `User`, `Member`, and `Tenant` models — what's the relationship?"
- **Architectural intent** — "I see events + jobs both being used. When does the team prefer one over the other?"
- **Unstated rules** — "Shared Vue components live in `packages/ui` — does that apply to ALL shared components or are there exceptions?"
- **Preferences not reflected in code** — "Tests use Pest. Do you prefer `it('does X')` syntax or `test('does X')`?"
- **Where to put NEW kinds of things** — "If I generated a new domain like 'Reports', where would it land?"

**Don't ask about things Layer 1-5 already answered.** That wastes user attention.

**Question economy:**
- Bundle related questions (`AskUserQuestion` supports multiple at once)
- Each question should be answerable in <30 seconds
- If you'd need to ask more than 10 questions, you're scanning too shallow — go back to deeper sampling

**Output**: Confirmed facts that fill the gaps your scan couldn't.

---

## Depth modes

All authoring agents accept a depth mode controlled by the parent skill:

| Mode | File-read budget | Interview questions max | When |
|------|------------------|------------------------|------|
| `shallow` | ≤5 | 0–2 | User provided a clear description; minimal scan needed |
| `standard` (default) | ≤25 | up to 5 | Sane default — enough signal, modest cost |
| `deep` | ≤100 | up to 15 | First-time onboarding of a complex monorepo; user wants thoroughness |

**Print the budget at start** of any scan operation: `"Scanning up to 25 files (--depth=standard). Use --depth=deep for more thoroughness or --depth=shallow to skip the scan."`

Stop early when you have enough signal. Going under budget is fine. Going over requires the user to bump depth.

---

## Output discipline

Every researcher's scan produces a **structured findings report** before generating any artifact:

```
## Stack
- Laravel 13 + PHP 8.5
- Vue 3.5 + Pinia + Vue Router 4
- No UI library detected (plain Vue + CSS)
- Tests: Pest (PHPUnit also present in composer.json but not used)

## Layout
- Monorepo (pnpm + turbo)
- Laravel at apps/api/ (flat app/ layout — no modules package)
- 2 Vue apps: apps/{web,admin}/src/
- Shared Vue in packages/ui/src/components/

## Conventions observed
- (high confidence) Controllers are thin; delegate to Action classes in app/Actions/
- (medium confidence) Form requests extend a project-specific BaseFormRequest
- (low confidence) Async data fetching — saw one example only

## Inferred but not verified — recommend asking
- Domain language: "Session" appears in many places — is this auth sessions or process sessions?
- Pest syntax preference: it() vs test()

## Files read (12)
- apps/api/composer.json
- apps/api/app/Http/Controllers/{example}.php
- ...
```

The report is shown to the user before generation so they can correct misreads. Then generation proceeds.

---

## What NOT to do

- ❌ Don't read every file you find. Sample.
- ❌ Don't ask questions Layer 1-5 already answered.
- ❌ Don't infer convention from a single file. Always validate with grep across multiple.
- ❌ Don't read `vendor/`, `node_modules/`, `dist/`, `build/`, `.git/`, `storage/`, `.next/`, `coverage/`.
- ❌ Don't fabricate conventions. If you can't find evidence, say "low confidence" or ask.
- ❌ Don't go over the depth budget without telling the user.

## Key principles

- **Triangulate, don't enumerate.** 3 samples + 1 grep = stronger signal than 30 file reads.
- **Prose tells you the why.** Always read README + docs/.
- **Recent code reveals current convention.** When in doubt, check git log.
- **Ask only what the code can't say.** Interview is for intent + preference, not facts.
- **Report before generating.** Show your work; let the user correct misreads.
