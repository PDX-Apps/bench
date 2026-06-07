# bench-docs

Generate or refresh **project documentation from the code** — an ADR, a README section, or API docs, grounded in the actual files rather than guesswork. The agent scans the relevant feature/module first, then writes docs that match what the code really does.

## What it ships
- **`/docs`** skill → **`docs-writer`** agent. Scans a feature/module and produces or refreshes:
  - an **ADR** (architecture decision record),
  - a **README** section, or
  - **API docs** — each tied to the real code paths it read.
- **DOC-001** pattern — the ADR format (context / decision / consequences) + when to write one.
- **DOC-002** pattern — a skimmable project/feature README structure (what it is, setup, usage, key files); also the base for API docs.

## Flow
```
/docs <subject> as adr      → writes/refreshes an ADR grounded in the code
/docs <subject> as readme   → writes/refreshes a feature README
/docs <subject> as api      → writes/refreshes API docs from the real handlers
```

## Install
```bash
bench addon add /path/to/bench/addons/bench-docs && bench rebuild
```
