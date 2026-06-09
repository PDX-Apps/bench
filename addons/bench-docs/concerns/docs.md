---
concern: docs
title: Documentation types & placement
order: 60
when: always
questions:
  - id: types
    ask: "Which kinds of docs does this project produce? Built-in: readme (feature/usage docs), user-guide (end-user, what to click), developer (how to use/extend a module — can be technical). Add your own as a comma list (e.g. marketing, runbook). Note: API references come from the laravel-swagger addon (OpenAPI), not here; ADRs/plans live in bench-plan."
    default: "readme, user-guide, developer"
  - id: placement
    ask: "Where should docs live? Describe the structure — a single root docs/, per-module docs/ folders, per-top-level-package, or split by audience (user vs developer in separate trees). A monorepo/module multi-level layout is fine to describe in a sentence or two."
    default: "a single root docs/ directory"
  - id: templates
    ask: "Do you have a template file the writer should match for any doc type? Give type=path pairs, comma-separated (blank for none) — e.g. developer=docs/templates/dev.md, marketing=docs/templates/one-pager.md. A template is the main way to shape a custom type like marketing."
    default: ""
output: config:.bench/docs.yaml
---

## Apply

Write `.bench/docs.yaml` — the project's documentation map, read by the `docs-writer` agent so it never guesses doc kinds or placement:

```yaml
# .bench/docs.yaml — read by the docs-writer agent
# Doc types this project produces. Built-in: readme, user-guide, developer (each
# has a pattern); custom types carry an audience + optional template the writer matches.
types:
  - name: readme        # built-in → DOC-001 (lives at the documented unit's root)
  - name: user-guide    # built-in → DOC-002 (end-user, what to click)
    dir: docs/guides
    audience: end users
  - name: developer     # built-in → DOC-003 (how to use/extend a module; technical)
    dir: docs/developer
    audience: developers
  # custom types from the user's list, e.g. a marketing one-pager (template-driven):
  - name: marketing
    dir: docs/marketing
    audience: marketing
    template: docs/templates/one-pager.md   # only if the user gave one

# Placement strategy — where a NEW doc goes. Captures the user's answer verbatim,
# so the writer follows the project's layout (root vs per-module vs by-audience).
placement: |
  {the user's placement answer, written as concrete rules the writer follows}
```

Rules for assembling it:

- **Types** — one entry per type the user listed. For the built-ins, set the conventional `dir` (`readme` has none — it sits at the documented unit's root; `user-guide` → `docs/guides`, audience "end users"; `developer` → `docs/developer`, audience "developers"). For each **custom** type (e.g. `marketing`), set `dir` (under the placement strategy), an `audience`, and a `template` only if the user supplied one — for freeform types like marketing the template is what gives the doc its shape.
- **Templates** — parse the `templates` pairs; attach each `path` to its type's `template:` key. Omit the key when no template was given.
- **Placement** — turn the user's free-text answer into a few concrete rules. For a monorepo + modules layout, spell out the levels explicitly (e.g. "global/cross-cutting docs → repo-root `docs/`; package-scoped → that package's `docs/`; module-scoped → that module's `docs/`"). For a by-audience split, name the trees (e.g. "user docs → `docs/user/`, developer docs → `docs/developer/`").
- Keep it to what the user actually said — don't invent types, directories, or audiences they didn't name.
