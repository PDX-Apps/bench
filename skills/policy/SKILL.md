---
description: Generate ONE Laravel authorization Policy class for a model. Use whenever the user mentions permissions, policies, "who can X", access control on a specific model.
argument-hint: [what the user needs]
---

You're the **/policy** skill. Translate the user's policy request into an enriched delegation to the `policy` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Policy class** — `{Model}Policy`
- **Model** the policy protects
- **Methods**: standard CRUD (`viewAny`, `view`, `create`, `update`, `delete`) + custom actions (`accept`, `deny`, `invite`, `markPaid`)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Policies/ 2>/dev/null
ls Modules/{Module}/app/Models/{Model}.php 2>/dev/null
ls Modules/{Module}/routes/api.php 2>/dev/null   # check existing ->can() usage
```

## Step 3: Resolve Ambiguity

- Model missing → flag: "Policy for `Bill` — model doesn't exist. Generate `/model` first?"
- Custom methods unclear → ask: "Standard CRUD only, or also non-CRUD actions (accept/deny/markPaid/etc.)?"
- Domain methods on model to delegate to → discover; if missing flag: "Policy delegates to `Bill::canBeViewedBy()`. Doesn't exist on the model — add it as a domain method?"

## Step 4: Build Context Blob

```
Context for policy agent:
- Module: {Module}
- Model: {Model} at Modules/{Module}/app/Models/{Model}.php
- Policy class: {Model}Policy
- Path: Modules/{Module}/app/Policies/{Model}Policy.php
- Methods: [viewAny, view, create, update, delete, accept, deny]
- Domain methods on model to delegate to: [canBeViewedBy(User), canBeAcceptedBy(User)]  (existing | to-be-added)
- Wiring: authorizeResource() in controller (CRUD) + ->can() on routes (custom)
- Existing siblings: [BillPolicy.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:policy"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Household/app/Policies/InvitationPolicy.php` with CRUD + `accept()` + `deny()`. All methods return bool, delegate to model domain methods. Auto-discovered. Wire CRUD via `authorizeResource()` in controller; non-CRUD via `->can()` on routes."

## When to Ask vs Assume

- Auto-discovery → assume yes
- Return `bool` from policy methods (NEVER Response) → always
- Delegate to model domain methods → always (don't put logic in policy)
