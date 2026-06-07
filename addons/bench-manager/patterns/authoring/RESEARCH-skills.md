# RESEARCH — Skills (project-local slash commands)

How to design and write a project-local skill (slash command) under `./.bench/skills/`. Used by the `skill-author` agent.

A **skill** is a slash-command surface in Claude Code. In Bench a skill is a **thin router** (~30–40 lines): it parses the user's request, resolves any ambiguity, builds a structured context blob, and **delegates the actual generation to a paired agent** via the `Task` tool. Skills coordinate; agents do the work. **A skill is almost always paired with an agent** — see [RESEARCH-agents.md](./RESEARCH-agents.md) for the worker side.

Apply [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md), plus the skill lens below. For overriding a *bundled* skill, also read [CONTRIBUTION-MODES.md](./CONTRIBUTION-MODES.md).

---

## When a project needs a custom skill

1. **A repeating multi-file generation flow** specific to this project that no core skill covers — e.g. the team has `app/Reports/` with report classes + a registry interface, and wants `/report create SalesByRegion` to scaffold a report class, its DTO, a test, and a registry entry, all in the team's exact shape.
2. **The user explicitly asked for one.**

If the project just needs an *existing* Bench skill to behave differently, that's a **pattern override** (`/bench-override`), not a new skill.

---

## Designing a NEW skill (the `/bench-slice` case)

You'll be given a domain ("a `/report` skill for `app/Reports/`"). Then:

### Step 1 — Confirm the artifact exists
Find 2–3 examples in the codebase (`app/Reports/*.php`). If none, flag it: the skill will make more assumptions and the first run needs close review.

### Step 2 — Map the full generation surface
List **every file** one invocation creates/touches — miss one and the skill breaks the workflow.

| File | Purpose |
|------|---------|
| `app/Reports/{Name}Report.php` | the report class |
| `app/Data/{Name}ReportData.php` | the DTO it returns |
| `tests/Unit/Reports/{Name}ReportTest.php` | test |
| `app/Reports/ReportRegistry.php` | registration (edited, not created) |

### Step 3 — Identify inputs
- **Required**: the noun (`SalesByRegion`).
- **Optional**: flags + sensible defaults; infer what you can from context (cwd, existing siblings).
- Aim for: required arg on the command line, defaults for the rest, prompt only when genuinely ambiguous.

### Step 4 — Identify the patterns the agent will read
The skill stays thin; the agent reads patterns. List the patterns the worker needs — both bundled (`patterns-built/...`) and the project's own (`.bench/patterns/...`, e.g. a `report` pattern authored alongside). If a needed pattern doesn't exist, flag it as a precondition.

---

## Skill file shape

```
.bench/skills/report/
└── SKILL.md
```

### SKILL.md template (thin router — match Bench's core skills)

```markdown
---
description: Generate a project Report class (+ DTO + test + registry entry). Use when the user wants a new report under app/Reports/ — "report for sales by region", "/report create X", "add a report".
argument-hint: [what the report should compute]
---

You're the **/report** skill. Translate the request into an enriched delegation to the `report` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Report name `{Name}` (PascalCase)
- What it computes (source models, grouping, filters)
- Returns a DTO? (default yes)

## Step 2: Resolve ambiguity
- Source data unclear → ask one focused question.
- Otherwise pick a sane default and proceed.

## Step 3: Build context blob
```
- Report: {Name}Report
- Computes: {description}
- DTO: {Name}ReportData
- Register in: app/Reports/ReportRegistry.php
```

## Step 4: Delegate
Task tool, `subagent_type: "report"`, pass the blob.

## Step 5: Synthesize
Report the files created, the DTO returned, and that it's registered.
```

---

## Writing rules

- **`description` is the trigger** — it's how Claude Code decides to invoke the skill. Be specific; list the phrasings a user would actually type.
- **Thin router, ~30–40 lines.** Parse → resolve → build blob → delegate → synthesize. No `Write`/`Edit`, no generation logic, no business rules — those live in the agent + patterns.
- **Always delegate via `Task`** to the paired agent (named after the skill — `/report` → `subagent_type: "report"`), so the heavy generation stays out of the main conversation.
- **No version-specific syntax** in the skill — defer it to the patterns the agent reads.
- **State preconditions** ("if the registry doesn't exist, ask first").

---

## Output the agent produces

`skill-author` returns:
1. **Scan report** (per METHODOLOGY) — the artifact + its full generation surface.
2. **A proposed `SKILL.md` draft** (thin router) + trigger phrases + inputs + the patterns the worker needs.
3. **A handoff to `agent-author`** to design the paired worker (named `{name}`, e.g. `report`).

After approval, write `./.bench/skills/{name}/SKILL.md`, the `agent-author` writes `./.bench/agents/{name}.md`, then `bench rebuild`.
