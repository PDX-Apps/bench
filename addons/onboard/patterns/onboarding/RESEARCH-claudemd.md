# RESEARCH — CLAUDE.md (project memory)

How to research a project and produce a useful `CLAUDE.md` at its root. Used by the `claudemd` researcher agent.

`CLAUDE.md` is the project-specific brief that every Bench agent reads before generating code. It's where conventions live that **the code can't reveal on its own**: domain language, intent, team preferences, where new artifacts go.

This pattern assumes you've already read [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md). Apply the 6 layers, then shape findings into a CLAUDE.md.

---

## What CLAUDE.md is for

A reader (human or AI) should be able to answer these after reading it:

1. **What is this project?** One paragraph: domain, what it does, who uses it.
2. **What's the stack?** Languages, frameworks, key libraries, versions.
3. **Where does code live?** Monorepo layout, module structure, frontend/backend boundary.
4. **How do I run / test / lint?** The exact commands.
5. **What conventions matter?** Naming, file location, patterns the team enforces.
6. **What domain terms mean what?** A small glossary if the domain has jargon.
7. **Where do NEW things go?** If I add a new module/component/page, where does it land?

If your draft can't answer those 7, it's not done.

---

## Researching for CLAUDE.md

Apply the methodology layers, but with this lens:

### Layer 1–2: Stack + layout
Cheap to gather. Always include in the final doc.

### Layer 3: Sampling
For each major artifact type (controllers, models, components, pages, stores), find 2–3 examples. Goal here isn't to extract patterns into separate files — it's to identify **which conventions to mention briefly in CLAUDE.md** and **which to call out as candidates for a project-local pattern override** (those go to the `pattern` researcher).

Examples worth mentioning in CLAUDE.md:
- Test framework (Pest vs PHPUnit, Vitest vs Jest)
- Test syntax preference (`it()` vs `test()`)
- Casing (snake_case DB, camelCase API)
- Where tests live (co-located vs `tests/`)
- Which UI library (or "none, plain Vue + CSS")
- Locale/i18n setup
- Auth mechanism

### Layer 4: Prose
Existing `README.md` and `docs/` are gold. Quote / paraphrase any team-stated rules — don't rewrite them.

If a `CLAUDE.md` already exists, **read it carefully**. You're refining, not replacing. Preserve user-written sections; only add or update what your scan revealed.

### Layer 5: Git
Recent churn tells you where active work lives — that's the convention that matters.

### Layer 6: Interview
Ask only what code can't say. Typical questions:

- "I see both `User` and `Member` models — what's the relationship?"
- "Pest is installed; do you prefer `it()` or `test()` syntax?"
- "Where should a NEW domain module go?"
- "Anything in the codebase you'd flag as 'don't copy this pattern, it's legacy'?"

---

## CLAUDE.md structure

A good `CLAUDE.md` is **short and scannable**. 100–300 lines for most projects. If it grows past ~500, split detail into `docs/` and link from CLAUDE.md.

Recommended skeleton (adapt to fit the project — don't force empty sections):

```markdown
# {Project Name}

{One-paragraph elevator: what it is, who it serves, how it's deployed.}

## Stack

- {Language + version}
- {Framework + version}
- {Key libraries — UI, state, data, auth, queue, …}
- {Test framework + chosen syntax}
- {Lint/format tools}

## Layout

{Describe the monorepo / module structure. A small ASCII tree often helps.}

```
apps/
  cloud/        # Laravel API
  desktop/      # Vue + Electron
  web/          # Vue web client
packages/
  ui/           # shared Vue components
```

- Laravel modules live at `apps/cloud/Modules/{Name}/`.
- Shared Vue components live at `packages/ui/src/components/`.
- App-specific Vue lives at `apps/{app}/src/`.

## Running

- Install: `{command}`
- Dev: `{command}`
- Test: `{command}`
- Lint / format: `{commands}`

## Conventions

{Only list things that override or sharpen Bench's defaults. Bullet form.}

- Tests use Pest, `it()` syntax, co-located as `*.spec.ts`.
- Form requests extend `Modules/{Name}/Http/Requests/BaseFormRequest`.
- Vue components are PascalCase files; composables are `useFoo.ts`.
- DB columns are `snake_case`; API payloads are `camelCase` (transformed at the boundary).
- No global event bus — cross-app comms go through Pinia stores or service classes.

## Domain glossary

{Only if the project has non-obvious jargon.}

- **Session**: a process session, NOT auth session. Auth tokens are called `Token`.
- **Tenant**: ...

## Where new things go

- New Laravel module → `apps/cloud/Modules/{Name}/` (use `/module create {Name}`).
- New Vue page → `apps/{app}/src/pages/`; routes auto-registered from filename.
- New shared component → `packages/ui/src/components/`; export via `packages/ui/src/index.ts`.

## Pointers

- Architecture decisions: `docs/architecture/`
- Bench addons / project-local overrides: `.bench/`
```

---

## Writing rules

- **Be specific.** "Tests use Pest" is good. "We care about testing" is noise.
- **Be terse.** Bullets > paragraphs. Skip filler.
- **No marketing copy.** This is a brief, not a pitch.
- **Cite paths.** "Modules live at `apps/cloud/Modules/`" beats "modules live in the modules folder".
- **Don't restate Laravel/Vue defaults.** Only call out what's project-specific.
- **Don't invent conventions.** If you didn't observe it, don't write it — or mark `low confidence — verify with team`.
- **Future-proof against drift.** Don't reference specific files that move often. Reference directories and patterns.

---

## When CLAUDE.md already exists

- Read it end-to-end first.
- Diff your findings against it — only suggest changes where:
  1. The file is silent on something your scan revealed.
  2. The file contradicts current code (convention has drifted).
  3. The user explicitly asked to refresh it.
- Present changes as a **diff or suggestion list**, not a full rewrite. The user wrote the original; respect it.

If `--force` is set, you may overwrite — but still surface what changed.

---

## Output the agent produces

The `claudemd` researcher returns:

1. **The scan report** (per METHODOLOGY-layered-scan.md output format).
2. **A proposed CLAUDE.md** (full draft for new projects, diff for existing).
3. **A list of follow-up items** for other researchers — e.g., "the controllers use a project-specific `BaseFormRequest` — recommend running `add-pattern` to capture that as a Bench pattern override."

The user reviews, edits, and the agent writes the file.
