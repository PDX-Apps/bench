---
description: |
  Change a Bench default for THIS project — override a pattern (how code is
  generated), a skill (how a slash command behaves), or an agent (how a worker
  runs). Use when the user says "I don't use DTOs", "override the controller
  pattern to use cache()", "we wrap responses in an ApiResponse envelope", "make
  /controller default to invokable", "drop the test step from /resource", "the
  migration worker should run a different formatter", "I prefer global helpers
  over DI", or any "change how Bench does X" request. Writes an append/anchor/
  replace contribution under ./.bench/ (never touches Bench core).
argument-hint: [what you want changed]
---

You're the **/bench-override** skill. Route the user's "change a Bench default" request to the right authoring agent, which writes a project-local contribution under `./.bench/`. You don't edit files yourself.

The user's request: **$ARGUMENTS**

## Step 1: Classify the target

What kind of Bench default does the change affect?

- **pattern** — *how code is generated* / a coding convention. Signals: "I don't use DTOs", "we extend BaseController", "wrap responses in X", "the controller pattern should…", "I prefer global helpers over DI", "drop the Don't section". **The common case.**
- **skill** — *how a slash command behaves* (its parse/route surface). Signals: "make `/controller` default to invokable", "drop the test step from `/resource`", "`/migration` should ask before X". (The skill author decides whether the paired agent also needs a change.)
- **agent** — *how a worker runs* (scaffolding/verification mechanics, not the code shape). Signals: "the migration worker should run a different formatter", "skip the static-analysis step", "be terser in the report".

## Step 2: Resolve ambiguity

- If it's unclear whether they mean the **code shape** (pattern) vs the **command behavior** (skill), ask one question: *"Do you want to change the generated code (pattern), or how the `/X` command behaves (skill)?"*
- If they named a specific bundled artifact, confirm it exists (`/bench-list` / `/bench-show` if needed); if not, surface that.
- Otherwise pick the obvious target and proceed.

## Step 3: Delegate (Task tool, `intent: fork`)

| Target | `subagent_type` |
|--------|-----------------|
| pattern | `pattern-author` |
| skill | `skill-author` |
| agent | `agent-author` |

Pass the brief: `intent: fork`, the target `name`/domain, the `change_request` (the user's words), `project_root` (cwd), `bench_install_root`. The author picks the lightest contribution mode (append/anchor/replace), shows it for approval, writes under `./.bench/`, and runs `bench rebuild`.

## Step 4: Synthesize

Report what was overridden: the target, the contribution mode chosen, the file under `./.bench/`, and that it's now active (any agent/skill that uses it picks up the change). Note it can be reverted by deleting that `.bench/` file + rebuilding.

## When to ask vs assume

- Target type obvious from the wording → don't ask, route it.
- "code shape vs command behavior" genuinely ambiguous → one question.
- Always defer the *mode* choice (append/anchor/replace) to the author — they pick the lightest that works.
