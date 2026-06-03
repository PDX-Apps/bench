# RESEARCH — Skills (project-local slash commands)

How to design and write a project-local skill (slash command) that lands under `./.bench/skills/`. Used by the `skill` researcher agent.

A **skill** is a slash command surface in Claude Code (e.g., `/api`, `/vue-component`). It parses the user's request, does any light project inspection needed to build context, then delegates the actual code generation to a paired **agent**. Skills are the user-facing front; agents are the worker behind them.

In Bench, **a skill is almost always paired with an agent.** The `/bench-add-skill` skill always generates both. This pattern covers the skill side; see [RESEARCH-agents.md](./RESEARCH-agents.md) for the worker side.

Apply [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md), plus the skill-specific lens below.

---

## When a project needs a custom skill

Add a project-local skill only when one of these holds:

1. **There's a repeating multi-file generation flow** specific to this project that doesn't match any core Bench skill. e.g., "/saga create OrderShipped" — generates an event class, a saga class, a test, and a route — none of which the generic `/event` or `/job` skills get right.
2. **A core skill needs project-specific framing** that's clearer as a new skill than as instructions in CLAUDE.md. e.g., the project has a custom CRUD generator with a unique shape.
3. **The user explicitly asked for one.**

If the project just needs Bench's existing skills to behave differently, that's a **pattern override** job, not a new skill.

---

## Researching to design a skill

You'll be given a domain ("I want a /saga skill") or asked to identify candidates ("are there workflows worth turning into skills?"). Either way:

### Step 1 — Confirm the artifact already exists

Find 2–3 examples in the codebase. If you can't find any, you're being asked to generate something the project doesn't yet have — fine, but flag it: the skill will need to make more assumptions, and the user should review the first generation closely.

### Step 2 — Map the full generation surface

For each example, list **every file** that gets created/touched. A skill must know all of them.

Example for `/saga create OrderShipped`:

| File | Purpose |
|------|---------|
| `Modules/Sales/Sagas/OrderShippedSaga.php` | The saga class |
| `Modules/Sales/Events/OrderShipped.php` | Triggering event (often pre-existing) |
| `Modules/Sales/Tests/Unit/Sagas/OrderShippedSagaTest.php` | Test |
| `Modules/Sales/routes/sagas.php` | Registration |

Anything else? Migrations? Translations? Feature flags? Don't miss a file — the skill that misses a file is the skill that breaks workflows.

### Step 3 — Identify the inputs

What does the user need to type to make this useful?

- **Required**: the noun (`OrderShipped`).
- **Optional**: module name (often inferrable from cwd), variations (`--with-compensation`, `--async`), naming overrides.

A skill that asks 5 questions before doing anything is annoying. A skill that asks 0 and gets things wrong is worse. Aim for: required arg from the command line, sensible defaults for the rest, prompt only when ambiguous.

### Step 4 — Identify the patterns the agent will need

The skill itself stays light — it doesn't contain code-generation logic. It hands the agent a structured brief and a list of patterns to read.

For `/saga`, the agent probably needs:
- `laravel/saga.md` (the artifact pattern — likely lives in `.bench/patterns/laravel/` if this is project-specific)
- `laravel/base/test.md` (test conventions)
- `laravel/base/event.md` (for the related event)

List these in the skill so the agent can load them.

### Step 5 — Decide where the skill belongs

- Project-local: `./.bench/skills/{name}/SKILL.md` — only this project sees it.
- Reusable addon: separate `{name}-addon` repo — multi-project use.
- Core: a PR to Bench itself — if it's broadly applicable.

If unsure, start project-local. Promote later if it earns its keep.

---

## Skill file shape

A skill is a directory:

```
.bench/skills/saga/
└── SKILL.md
```

### SKILL.md template

```markdown
---
name: saga
description: |
  Use this skill when the user wants to scaffold a Saga (long-running orchestration)
  in this project. Triggers on phrases like "/saga create X", "scaffold a saga",
  "add an OrderShipped saga", or any request to create a saga class with its
  event, test, and route registration.
---

# /saga

Scaffolds a Saga + its triggering event reference + test + route registration
in the appropriate Module.

## Usage

```
/saga create {Name}                       # default — assumes current Module
/saga create {Name} --module {Module}     # explicit module
/saga create {Name} --with-compensation   # also scaffold compensation handler
```

## What this skill does

1. **Parse the request**: extract `{Name}`, optional `{Module}`, flags.
2. **Resolve the Module**: if not provided, infer from the current working directory
   (look for nearest `Modules/{Module}/` ancestor). If ambiguous, ask the user.
3. **Verify pre-conditions**: confirm the triggering event exists at
   `Modules/{Module}/Events/{Name}.php`. If not, ask whether to scaffold it first
   (offer to delegate to `/event create {Name}`).
4. **Hand off to the worker agent** (`saga-worker`) with a structured brief:
   - Module name + path
   - Saga name
   - Event name
   - Flags
   - List of patterns to read: `laravel/saga.md`, `laravel/base/test.md`
5. **Report back** what was generated.

## What this skill does NOT do

- Run migrations.
- Register routes outside of `Modules/{Module}/routes/sagas.php`.
- Modify existing sagas (use `/refactor` for that).

## Delegating to the agent

Use the `Task` tool with `subagent_type: "saga-worker"`. Pass the structured brief
as the first message. Wait for the agent's summary; relay it to the user.

Example invocation:

```
Task(
  subagent_type: "saga-worker",
  description: "Scaffold OrderShipped saga",
  prompt: """
  Generate a Saga in this project:
  - Module: Sales
  - Saga name: OrderShipped
  - Triggering event: Modules/Sales/Events/OrderShipped.php (exists)
  - Flags: --with-compensation
  - Patterns to read: laravel/saga.md, laravel/base/test.md
  Follow the patterns. Report the files created.
  """
)
```
```

---

## Writing rules

- **Description is critical.** It's what Claude Code uses to decide when to invoke the skill. Be specific about the trigger phrases. Be a little "pushy" — name the variations users might phrase it as.
- **Keep the skill body short.** Under 150 lines. Detailed generation logic belongs in the agent + patterns, not the skill.
- **Skills coordinate; agents do.** The skill parses input, gathers context, hands off. It should not contain `Write` or `Edit` calls directly except for trivial scaffolding.
- **Always delegate via Task.** Even one-file skills should hand off to an agent for context isolation. The skill's job is to keep the *main conversation* clean.
- **State preconditions explicitly.** "If the event doesn't exist, ask before generating" — make the skill the gatekeeper.
- **Document what it WON'T do.** Avoids scope creep and surprise behavior.

---

## Output the agent produces

The `skill` researcher returns:

1. **Scan report** (per METHODOLOGY) — confirming the artifact exists and what files compose it.
2. **A proposed skill design**: trigger phrases, args, the full generation surface, patterns needed.
3. **A proposed `SKILL.md` draft.**
4. **A handoff to the `agent` researcher** to design the paired worker agent (`{name}-worker`).

After user review, the skill writer creates `./.bench/skills/{name}/SKILL.md` and triggers `bench rebuild`. The agent researcher runs in the same flow to produce `./.bench/agents/{name}-worker.md`.
