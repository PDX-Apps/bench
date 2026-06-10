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
