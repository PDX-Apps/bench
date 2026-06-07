---
description: Generate ONE Laravel authorization Policy class for a model. Use whenever the user mentions permissions, policies, "who can X", access control on a specific model.
argument-hint: [what the user needs]
---

You're the **/policy** skill. Translate the user's policy request into an enriched delegation to the `policy` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Policy class** — `{Model}Policy`
- **Model** the policy protects
- **Methods**: standard CRUD (`viewAny`, `view`, `create`, `update`, `delete`) + custom actions (`accept`, `deny`, `assign`, `cancel`)

## Step 2: Resolve Ambiguity

- Model doesn't exist → flag: "Policy for `{Model}` — the model doesn't exist. Generate `/model` first?"
- Custom methods unclear → ask: "Standard CRUD only, or also non-CRUD actions (accept/deny/cancel/etc.)?"
- Policy should delegate to a model domain method that doesn't exist yet → flag: "This delegates to `{Model}::isOwnedBy()`, which isn't on the model — add it as a domain method?"

## Step 3: Build Context Blob

```
Context for policy agent:
- Model: {Model}
- Policy class: {Model}Policy
- Methods: [viewAny, view, create, update, delete, accept, deny]
- Domain methods on model to delegate to: [isOwnedBy(User), isInvitee(User)]  (existing | to-be-added)
```

## Step 4: Delegate

Task tool, `subagent_type: "policy"`, pass the blob.

## Step 5: Synthesize

Report the policy path, the methods added (CRUD + custom), and that each returns `bool` and delegates to model domain methods. Note it's auto-discovered, and that abilities are wired via `#[Authorize]` on the controller method.

## When to Ask vs Assume

- Auto-discovery → assume yes (no manual registration)
- Return `bool` from policy methods (never a `Response`) → always
- Delegate to model domain methods → always (don't put logic in the policy)
