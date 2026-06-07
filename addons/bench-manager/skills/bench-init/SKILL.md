---
description: |
  First-run setup that tailors Bench to THIS project. Scans for where the project
  deviates from Bench's defaults (custom base classes, auth/permissions, layout,
  test framework, response shape) and for proprietary domains worth a slice, then
  offers to capture each as a ./.bench/ override or a skill→agent→pattern slice.
  Use on "/bench-init", "set up Bench for this project", "tailor Bench to my
  codebase", "initialize Bench". Does NOT write your CLAUDE.md — that stays yours.
argument-hint: "[--depth=shallow|standard|deep]"
---

You're the **/bench-init** skill. Tailor Bench to this project by detecting what's non-standard and offering to capture each, routing to the authoring agents. You orchestrate; you don't author files yourself, and you **never write the project's CLAUDE.md**.

The user's request: **$ARGUMENTS**

## Step 1: Scan (project-scanner)

Stack + frontend are already known from install — don't re-detect. Delegate the deviation scan:

```
Task(subagent_type: "project-scanner", description: "Scan project for Bench deviations", prompt: """
  Scan this project and report deviations from Bench defaults + slice candidates.
  depth: {parsed --depth or standard}
  project_root: {cwd}   bench_install_root: {install}
  Read-only — return the menu, write nothing.
""")
```

## Step 2: Present the menu (opt-in)

Relay the scanner's findings as a short checklist the user picks from — each item is opt-in, "skip all" is always valid:

```
Bench scanned your project. Here's what's non-standard — capture any of these?

Overrides (teach Bench your conventions):
  [ ] 1. Controllers extend a custom BaseController        → pattern override
  [ ] 2. Permissions via spatie/laravel-permission         → policy override
  [ ] 3. Pest, tests co-located                            → test override

Slices (Bench-grade scaffolding for your own domains):
  [ ] A. app/Reports/ (11 classes + registry)              → /report skill→agent→pattern

Skip any — you can always run /bench-override or /bench-slice later.
```

Use `AskUserQuestion` to collect the selections. Nothing is captured without the user opting in.

## Step 3: Capture each accepted item (defer_rebuild: true)

- **Override items** → delegate to the matching author in `intent: fork`, `defer_rebuild: true`:
  - convention/code shape → `pattern-author`; command behavior → `skill-author`; worker mechanics → `agent-author`.
- **Slice items** → run the slice sequence (same as /bench-slice): `pattern-author` (intent capture) → `skill-author` (intent new, which cascades to `agent-author`), all `defer_rebuild: true`.

Each author shows its draft for approval before writing under `./.bench/`.

## Step 4: One rebuild + summary

After all accepted items are written:

```bash
{install}/bin/bench rebuild
```

```
Bench tailored to {project}.
Overrides written: {list}
Slices written:    {list}
Skipped:           {list}

Your CLAUDE.md was untouched. Add more anytime:
  /bench-override <change>   ·   /bench-slice <domain>   ·   /bench-list
```

## Notes

- **Never writes CLAUDE.md.** Project context bench needs rides inside the `.bench/` overrides (each pattern carries its own `## Location`); the user's CLAUDE.md is theirs.
- **Everything is opt-in.** A first run that captures nothing is a valid outcome — the user just learned what's non-standard.
- **One rebuild** at the end (`defer_rebuild: true` on every author call).
- Surface the scanner's low-confidence/unverified items as questions, not silent assumptions.
