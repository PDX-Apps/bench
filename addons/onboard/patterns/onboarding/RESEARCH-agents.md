# RESEARCH — Agents (project-local worker agents)

How to design and write a project-local worker agent that lands under `./.bench/agents/`. Used by the `agent` researcher agent.

A **worker agent** is the subagent invoked by a skill (via the `Task` tool) to do the actual code generation. It runs in isolated context, reads only the patterns it needs, scaffolds files, runs verification, and returns a summary.

Worker agents in Bench are almost always paired 1:1 with a skill. This pattern covers the agent side; see [RESEARCH-skills.md](./RESEARCH-skills.md) for the front-end side.

Apply [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md), plus the agent-specific lens below.

---

## When a project needs a custom worker agent

Whenever you're adding a project-local skill, you almost always also need a paired worker. The `/bench-add-skill` flow generates both in one pass — that's the default.

Standalone agents (without a paired skill) are rare and usually take the form of:

- **Specialist analyzers** invoked from other agents — e.g., a `migration-reviewer` called by `/migration` after generation.
- **Reusable subroutines** shared across multiple skills.

If you're tempted to write a standalone agent, ask whether it should just be inlined into the calling agent's flow.

---

## Researching to design an agent

You already have the skill's design (from `RESEARCH-skills.md`). The agent design follows from it.

### Step 1 — Re-read the skill's brief

Specifically: what does the skill hand the agent? What does it expect back?

If the skill says "the agent will be passed `{Module}`, `{Name}`, `{flags}`, and a list of patterns to read" — those are the agent's inputs, exactly.

### Step 2 — Identify the patterns it reads

Bench's superpower is that agents read pattern files lazily. The agent should:

- Load **only the patterns relevant to its artifact**.
- Load the project's `CLAUDE.md` (this is a hard rule for any Bench worker agent — see below).
- Skip everything else.

Confirm the list of patterns from your skill research. If the project has overrides at `.bench/patterns/{group}/{name}.md`, the agent reads those (the build pipeline ensures they win over base).

### Step 3 — Identify verification steps

A good worker agent doesn't just write files and stop. It verifies:

- **Syntax** — run `phpstan`, `tsc`, or whatever the project uses.
- **Tests** — at least run the new test it scaffolded.
- **Format** — run `pint`, `prettier`, `eslint --fix`.

Find the project's commands during your Layer 1 manifests scan and bake them into the agent.

If a project uses non-standard commands, the agent must know — there's no "guess" mode here.

### Step 4 — Identify the report format

What does the agent return to the skill (and ultimately the user)?

A good summary:
- Lists files created (with paths).
- Mentions any verification that ran + result.
- Surfaces any decisions the agent made on the user's behalf (e.g., "inferred module = Sales from cwd").
- Flags anything that needs human follow-up (e.g., "test fixture data is a stub — replace with real data").

Keep it short. Bullet list, ~10 lines max.

---

## Agent file shape

```
.bench/agents/saga-worker.md
```

Single markdown file with YAML frontmatter.

### Template

```markdown
---
name: saga-worker
description: |
  Worker agent for the /saga skill. Generates a Saga class, its test, and route
  registration in the specified Module. Reads only the saga-relevant patterns.
tools: Read, Write, Edit, Bash, Glob, Grep
---

# saga-worker

Generates a Saga + test + route registration for this project.

## Inputs (from the calling skill)

- `module`: the Module name (e.g., "Sales")
- `name`: the Saga name (e.g., "OrderShipped")
- `event`: the triggering event class (existing or to-scaffold)
- `flags`: `--with-compensation`, `--async`, etc.

## Workflow

1. **Read context**:
   - `CLAUDE.md` at the project root (always — it has project-specific overrides).
   - `<PLUGIN_ROOT>/patterns-built/laravel/saga.md`
   - `<PLUGIN_ROOT>/patterns-built/laravel/base/test.md`

2. **Verify pre-conditions**:
   - `Modules/{module}/` exists.
   - `Modules/{module}/Events/{event}.php` exists. If not, return early — the skill should have handled this.

3. **Generate files** (follow the patterns exactly):
   - `Modules/{module}/Sagas/{name}Saga.php`
   - `Modules/{module}/Tests/Unit/Sagas/{name}SagaTest.php`
   - Update `Modules/{module}/routes/sagas.php` to register the saga.

4. **Verify**:
   - Run `./vendor/bin/pint Modules/{module}/Sagas/{name}Saga.php` (format).
   - Run `./vendor/bin/phpstan analyse Modules/{module}/Sagas/` (static analysis).
   - Run `./vendor/bin/pest --filter={name}SagaTest` (test runs).

5. **Report**:

   ```
   Created:
   - Modules/Sales/Sagas/OrderShippedSaga.php
   - Modules/Sales/Tests/Unit/Sagas/OrderShippedSagaTest.php
   Updated:
   - Modules/Sales/routes/sagas.php (registered OrderShippedSaga)

   Verified:
   - pint: OK
   - phpstan: OK
   - pest: 1 passed (stub test — replace fixture data before relying on it)

   Notes:
   - Inferred module = "Sales" from cwd. If this is wrong, run `/saga create OrderShipped --module {Module}`.
   ```

## Rules

- Never modify files outside `Modules/{module}/`.
- Never delete or rewrite existing sagas. If `{name}Saga.php` already exists, stop and report.
- Always run the verification step. If any step fails, report the failure and do NOT claim success.
- If a generated file fails formatting or static analysis, fix the generated file — don't suppress the error.
```

---

## Writing rules

- **Always read CLAUDE.md first.** This is non-negotiable for Bench worker agents. The project's CLAUDE.md overrides defaults.
- **Lazy pattern loading.** Read only what you'll use. Patterns are token-expensive.
- **Verify, don't just generate.** A worker that writes broken code is worse than one that doesn't run.
- **Fail loudly.** If a verification step fails, surface it. Never silently swallow errors. Never claim success when something failed.
- **Don't touch unrelated files.** A worker that "helpfully" reformats every file it sees is a worker that breaks PRs. Stay in your lane.
- **Be honest in the report.** If you generated a stub test with placeholder data, say so. Future-you (and the user) needs to know.
- **One artifact type per agent.** Don't write a "Sales-everything-worker." Each agent has one job.

---

## Tools to grant

Default tool set for a code-generating worker:

```yaml
tools: Read, Write, Edit, Bash, Glob, Grep
```

Add `Task` only if the agent needs to spawn its own subagents (rare — usually a sign the work should be split into separate skills).

Don't grant tools the agent doesn't need. Smaller permission surface = fewer surprises.

---

## Output the agent produces

The `agent` researcher returns:

1. **A proposed agent design**: inputs, workflow, verification commands, report format.
2. **A proposed agent markdown file**.
3. **Confirmation that it pairs cleanly with the skill** (matching inputs, matching expected outputs).

After user review, the writer creates `./.bench/agents/{name}-worker.md` and triggers `bench rebuild`. The skill + agent are now both live.

## See also

- [RESEARCH-skills.md](./RESEARCH-skills.md) — the paired skill design
- [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md) — the shared scan methodology
