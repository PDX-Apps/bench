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
2. Run `detect:` (if present) for a suggested default.
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

## Finish — one rebuild + summary

```bash
{install}/bin/bench rebuild
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
