# Example CLAUDE.md snippet — route everything through Bench

Paste the section below into your project's `CLAUDE.md` if you want Claude Code to **default to
Bench** for code generation — so natural-language requests ("I need an endpoint", "add a
component") are routed through Bench's project-aware patterns instead of hand-written generic
code. It routes through the **delegator** commands (`/laravel`, `/frontend`, `/bench`), which
exist in **both** the `standard` and `compact` profiles, so it works with either.

---

## Building in this project — use Bench

This project uses the **Bench** plugin. Bench knows this project's conventions (auth strategy,
test framework, response shape, layout, module structure, UI library, …) and generates code
that fits them. **Route code generation through Bench** rather than writing Laravel / Vue /
React by hand — its output matches the project's patterns the first time, so there's nothing to
re-shape in review.

### HARD REQUIREMENT — all backend code generation goes through Bench

Reading a Bench pattern and then writing the code yourself is **not** using Bench — it loses the
isolation that makes the output correct, and that is exactly how conventions get skipped.

- **Never hand-write a Laravel artifact** (Action, Controller, FormRequest, Resource, DTO/Data, Model,
  Migration, Policy, Job, Event, …) under `app/**` or `Modules/**/app/**`. It must come from the
  matching Bench skill, which delegates to the worker agent that builds it in isolated context.
- **For a feature touching more than one layer, use `/bench:implement <feature>`** — it sequences
  request → DTO → action → controller → resource → tests. Never cherry-pick one skill and hand-write the rest.
- **Side effects always live in an Action** (`execute(User $user, …)`), never inlined in a controller.
  **Input is typed through a DTO** via `FormRequest::toDto()`.
- **If Bench lacks a pattern, STOP and ask** — don't invent a flatter shape or record a private remediation.

**Default to Bench for any "build / add / create / implement / scaffold" code-related request:**

| When the request is…                                                                                                                      | Use                                       |
|-------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| A backend artifact or feature — endpoint, controller, model, migration, action, job, policy, request, resource, event, console command, … | `/laravel <what you want>`                |
| A frontend artifact or feature — component, page, store, composable/hook, route, form, validator, i18n                                    | `/frontend <what you want>`               |
| A whole feature spanning both layers, or a spec / PRD / ticket                                                                            | `/bench <what you want>` (routes to both) |
| "what can this do?"                                                                                                                       | `/help`                                   |

These are **routers**: they classify the request, inspect the project, and delegate to the right
worker agent(s) — you don't need to pick a granular command. For example:

- "I need an endpoint to list a user's orders" → `/laravel create an endpoint to list a user's orders`
- "Add an OrderCard component" → `/frontend add an OrderCard component`
- "Implement the team-invitation feature" → `/bench implement the team-invitation feature`

**Don't** hand-write a controller, model, migration, or component from scratch when Bench can
generate it to this project's conventions. If Bench genuinely lacks a pattern for what's asked,
it will say so (and can look it up) — that's the signal to fall back, not the default.

<!-- If you use the preflight addon, uncomment:
When a unit of PHP work is complete — before committing, or reporting the task done (NOT after
every single file) — verify with Preflight: run `/preflight` (or `vendor/bin/preflight --fix
--dirty --format=agent`, then fix every finding until it exits 0).
-->
