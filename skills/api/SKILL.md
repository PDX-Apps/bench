---
description: Generate Laravel HTTP layer code — controllers, routes, FormRequests, API Resources, request validation, response transformation. Use whenever the user mentions endpoints, APIs, controllers, routes, request validation, or any HTTP-layer work in a Laravel project, even if they don't explicitly say "API".
argument-hint: [what the user needs]
---

You're the **/api** skill — the HTTP-layer coordinator. Your job is to translate the user's feature request into a clear, actionable delegation to the `api` agent. Skip steps that don't apply (e.g., obvious cases) but never skip Step 5.

The user's request: **$ARGUMENTS**

## Step 1: Parse the Request

Extract from `$ARGUMENTS`:
- **Module name** (e.g., Bill, Household, Payments). If the user mentions a model/resource, infer the module.
- **Resource** the endpoint is about (e.g., "bill", "invitation", "household member").
- **Operation type** — one of:
  - `crud` — standard list/show/create/update/delete (use HTTP-001 resource controller)
  - `invokable` — single specific action like "verify email", "mark paid" (HTTP-005)
  - `grouped` — 2-5 related non-CRUD actions on the same resource like "accept/deny/cancel" (HTTP-006)
- **Artifacts needed** — controller is mandatory; FormRequest/Resource are usually needed too. Routes always needed. Decide based on the request.

## Step 2: Inspect the Project

Run quick checks (don't read whole files — just listings):

```bash
# Module exists?
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"

# Existing controllers (for naming conventions)
ls Modules/{Module}/app/Http/Controllers/ 2>/dev/null

# Existing requests (for naming + style conventions)
ls Modules/{Module}/app/Http/Requests/ 2>/dev/null

# Existing resources
ls Modules/{Module}/app/Http/Resources/ 2>/dev/null

# Model exists for this resource?
ls Modules/{Module}/app/Models/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

If after Step 2 something is unclear, ask **one** focused question or pick a sane default and confirm in one line:

- Module missing → ask user to confirm module OR suggest `/new-module {Name}` first
- Operation type ambiguous → ask: "Standard CRUD, single action (invokable), or grouped non-CRUD actions?"
- Model missing → confirm: "No `Bill` model found. Should I assume you'll create it via `/model` first, or generate the controller against a not-yet-existing model?"

For obvious cases (e.g., user said "create endpoint to mark a bill paid" → invokable, model exists), skip this step and proceed.

## Step 4: Build Context Blob

Assemble what the agent needs to work without re-discovering anything:

```
Context for api agent:
- Module: {Module}
- Resource: {ResourceName}
- Operation: {crud|invokable|grouped}
- Artifacts to generate: [controller, request, resource, route]
- Existing siblings:
  - Controllers: [list]
  - Requests: [list]
  - Resources: [list]
- Naming convention observed: {e.g., "AcceptInvitationController" — invokable controllers prefixed with verb}
- Model: {ModelName} ({exists|to-be-created})
- Spec ref (if user mentioned one): SPEC-XXX
```

## Step 5: Delegate to the `api` Agent

Use the Task tool. `subagent_type: "bench:api"`. Pass the context blob from Step 4 as the prompt — NOT raw `$ARGUMENTS`. The agent now has everything it needs and won't waste tokens re-inspecting.

## Step 6: Synthesize for the User

The agent returns a summary. Re-frame it for the user at the feature level:

> "Created `InviteMemberController` (invokable), `InviteMemberRequest`, `InviteMemberResource`, route `POST /api/households/{id}/invitations`. Authorized via `HouseholdPolicy@invite`. Tests: pending — invoke `/feature-test` to add coverage."

Mention any follow-ups the agent flagged (missing model, missing policy, suggested pattern proposal).

## When to Ask vs Assume

- **Module obviously named** in request → don't ask, use it
- **Module ambiguous** ("add an endpoint to invite a member" → Household? Bill? User?) → ask
- **Operation type obvious** ("mark paid" → invokable; "CRUD for bills" → crud) → don't ask
- **Operation type ambiguous** → ask one question with the 3 options
- **Tests requested** → don't generate here; suggest `/feature-test` after

## Anti-Patterns

- Passing raw `$ARGUMENTS` to the agent (defeats the purpose of this skill)
- Asking 3 questions when one disambiguates the rest
- Skipping the inspect step (agent will re-do it, wasting tokens)
- Reading whole files in inspection — only need listings
