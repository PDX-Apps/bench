---
description: Run Bench's guided concern setup — interview the user about essential project concerns (auth, test framework, permissions, response shape, layout, and any addon concerns) and write the matching .bench/ overrides/config. Use on "/bench-configure", "set up auth/permissions/CI for Bench", "configure a concern", or to (re)configure a specific concern.
argument-hint: "[optional: concern name, e.g. auth | test-framework | ci]"
---

You're the **/bench-configure** skill. Run the declared concerns: ask their questions, then delegate the writing to `concern-runner`. You own the interview (subagents can't ask the user).

The user's request: **$ARGUMENTS**

## Step 1: Discover concerns
List `<PLUGIN_ROOT>/concerns/*.md` (core + installed addons, mirrored at install). If `$ARGUMENTS` names one, run just that; else run all, sorted by `order`.

## Step 2: Per concern, in order
1. Read the concern file. If `when:` is a shell test, run it; skip the concern if it fails.
2. If `detect:` is present, run it — its output is the suggested default.
3. **Ask the `questions`** with `AskUserQuestion` (bundle a concern's questions into one prompt; pre-fill `default`/detect). Let the user accept the default or change it. Skipping a concern is always allowed.
4. **Delegate to `concern-runner`** (Task) with `{ concern_file, answers, project_root: cwd, defer_rebuild: true }`.

## Step 3: One rebuild + report
After all concerns, run `bench rebuild` once. Report per concern: what was asked, what was written (the `.bench/` overrides + any config), and which patterns were updated.

## Notes
- Concerns are the **reliable, declared** path (essentials always get asked; every affected pattern gets updated). For the long tail beyond declared concerns, see `/bench-init` (which runs concerns first, then offers scanning).
