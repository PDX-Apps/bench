# RESEARCH — Agents (project-local worker agents)

How to design and write a project-local worker agent under `./.bench/agents/`. Used by the `agent-author` agent.

A **worker agent** is the subagent a skill invokes (via `Task`) to do the actual generation. It runs in isolated context, reads only the patterns it needs, scaffolds files, runs the project's verification, and returns a summary. Worker agents are paired 1:1 with a skill — this lens covers the agent side; for the front.

Apply [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md), plus the agent lens below.

---

## The current Bench agent shape

A Bench agent is **thin and pattern-driven**. It does NOT embed idiom — it routes to patterns (which are the version-aware source of truth) and generates. Critically:

- **No "read CLAUDE.md first" block.** Claude Code injects the project's `CLAUDE.md` into the agent's context automatically — never instruct the agent to read it, and never duplicate its content.
- **No version-specific syntax** in the agent body. Whether to use `#[Attribute]` vs an older idiom is the *pattern's* call (patterns carry version overrides); the agent just says "follow the pattern."
- **Pattern Lookup table** = the source of truth for which patterns to read.
- **Verify with the project's real commands**, scoped to the files it generated.

This mirrors how Bench's own core agents are written.

---

## Designing an agent (from the skill's brief)

### Step 1 — Re-read the skill's brief
The agent's inputs are exactly what the skill hands off (the context blob). Don't invent extras.

### Step 2 — Pattern Lookup
List only the patterns this agent reads — both bundled (`patterns-built/...`) and the project's own (`.bench/patterns/...`, which the build merges to win). The agent reads them lazily, only for the artifact it's generating.

### Step 3 — Verification
Discover the project's actual commands in the Layer-1 manifest scan and bake them in, scoped to generated files only:
- format (`pint`, `prettier`), static analysis (`phpstan`, `tsc`), tests (the project's `test` command — `php artisan test --filter=…`, `pest`, `vitest`).
Don't guess — use what the project actually uses.

### Step 4 — Report format
Short bullet list: files created/updated (paths), verification run + result, decisions made on the user's behalf, anything needing follow-up.

---

## Agent file shape

```
.bench/agents/report.md
```

### Template (match Bench's core agents)

```markdown
---
name: report
description: Worker for the /report skill. Generates a Report class + DTO + test and registers it. Reads only the report patterns.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---
You generate ONE project Report. The skill provided enriched context. Read ONLY the patterns needed.

## Pattern Lookup

| Need | Read |
|------|------|
| Report structure | `<PLUGIN_ROOT>/patterns-built/laravel/reports/REPORT-001-structure.md` |
| DTO | `<PLUGIN_ROOT>/patterns-built/laravel/dto/DTO-001-structure.md` |

## Process

1. Read REPORT-001.
2. Scaffold: `php artisan make:class app/Reports/{Name}Report --no-interaction` (or the project's generator).
3. Implement following the pattern; create the `{Name}ReportData` DTO; register in `app/Reports/ReportRegistry.php`.
4. Run the project's test for it (e.g. `php artisan test --filter={Name}ReportTest`).

## Return

- Files created/updated (paths)
- Verification result
- Anything needing follow-up
```

---

## Writing rules

- **No "read CLAUDE.md" step.** It's auto-injected; instructing the agent to read it is wrong (and duplicates context). Don't add it.
- **No version-specific syntax in the body** — defer the idiom to the pattern (patterns carry the version overrides).
- **Lazy pattern loading** — only what the artifact needs.
- **Verify with the project's real commands**, scoped to generated files; **fail loudly** — never "continue anyway", never claim success on a failed step.
- **Stay in your lane** — don't touch or reformat unrelated files; if a target already exists, stop and report.
- **Be honest in the report** — a stub test is reported as a stub.
- **One job per agent.** Minimal tools (`Read, Write, Edit, Bash, Glob, Grep`; add `Task` only if it spawns subagents — rare).

---

## Output the agent produces

`agent-author` returns: the proposed agent markdown + confirmation it pairs cleanly with the skill (inputs match the skill's blob). After approval, write `./.bench/agents/{name}.md`, then `bench rebuild`.
