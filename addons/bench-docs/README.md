# bench-docs

Generate or refresh **audience-facing documentation from the code** — a README/feature doc, an end-user guide, or a developer guide, grounded in the actual files rather than guesswork. The agent scans the relevant feature/module first, then writes docs that match what the code really does.

This addon owns the **prose that teaches and onboards**. It deliberately does **not** produce:
- **API references** — that's the `laravel-swagger` addon (OpenAPI, generated from the code).
- **ADRs / build plans** — those are decision and planning artifacts in `bench-plan`.

## What it ships
- **`/docs`** skill → **`docs-writer`** agent. Scans a feature/module and produces or refreshes:
  - a **README** / feature doc (what it is, setup, usage, key files),
  - a **user guide** (end-user, what to click — plain language, no code),
  - a **developer guide** (how to *use/extend* a module — its contract, extension points; technical, but not an ADR or a plan), or
  - a **custom type** you defined (e.g. a marketing one-pager, template-driven) — each tied to the real code paths it read.
- **DOC-001** pattern — README / feature-doc structure.
- **DOC-002** pattern — user-guide structure (task/click steps, real on-screen labels, screenshots where they earn it).
- **DOC-003** pattern — developer-guide structure (concepts → the real contract/interface → how to extend → usage).
- **`docs` concern** — at setup, captures your **doc types**, **placement strategy** (root `docs/` vs per-module vs per-package vs by-audience — multi-level for monorepos), and any **templates** into `.bench/docs.yaml`, so the writer follows your layout instead of guessing.

## Flow
```
/docs <subject> as readme       → writes/refreshes a feature README
/docs <subject> as user-guide   → writes an end-user, click-through guide
/docs <subject> as developer    → writes a developer guide (contract + how to extend)
/docs <subject> as <custom>     → writes a custom-type doc (per .bench/docs.yaml)
```

Placement and types come from `.bench/docs.yaml` (set up by the `docs` concern); without it, docs land in their conventional locations.

## Install
```bash
bench addon add bench-docs && bench rebuild
```
